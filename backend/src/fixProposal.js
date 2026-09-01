export class FixProposalConfigError extends Error {}
export class FixProposalRequestError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.status = status;
  }
}

export function getFixProposalConfig() {
  return {
    endpoint: process.env.ONEOPS_LLM_ENDPOINT || '',
    apiKey: process.env.ONEOPS_LLM_API_KEY || process.env.OPENAI_API_KEY || '',
    model: process.env.ONEOPS_LLM_MODEL || '',
  };
}

export async function proposeFix({ diagnosis, codeContext, incident, ragResults } = {}) {
  const config = getFixProposalConfig();
  if (!config.endpoint) throw new FixProposalConfigError('LLM endpoint is not configured.');
  if (!config.apiKey) throw new FixProposalConfigError('LLM API key is not configured.');
  if (!config.model) throw new FixProposalConfigError('LLM model is not configured.');

  const attempts = [];
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const parsed = await requestFixProposal(config, {
      diagnosis,
      codeContext,
      incident,
      ragResults,
      previousError: attempts[attempts.length - 1],
    });
    if (parsed?.status === 'failed') {
      return { status: 'failed', error: String(parsed.error || 'The model could not propose a safe reviewable change.') };
    }

    const proposal = normalizeProposal(parsed, codeContext);
    if (proposal.status === 'failed') return proposal;

    const validationError = validateUnifiedDiff(codeContext?.content || '', proposal.diff, codeContext?.path || '');
    if (!validationError) {
      if (attempt > 0) {
        console.warn('[OneOps] FIX_PROPOSAL_RETRY_SUCCEEDED', { attempt: attempt + 1, path: codeContext?.path });
      }
      return proposal;
    }

    attempts.push(validationError);
    console.warn('[OneOps] FIX_PROPOSAL_DIFF_REJECTED', {
      attempt: attempt + 1,
      path: codeContext?.path,
      reason: validationError,
    });
  }

  return {
    status: 'failed',
    error: `The model did not return an applicable unified diff after ${attempts.length} attempts. Last validation error: ${attempts[attempts.length - 1] || 'unknown'}`,
  };
}

async function requestFixProposal(config, { diagnosis, codeContext, incident, ragResults, previousError }) {
  const response = await fetch(config.endpoint, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${config.apiKey}`,
    },
    body: JSON.stringify({
      model: config.model,
      messages: [
        {
          role: 'system',
          content: [
            'You are the OneOps explainable fix proposal layer.',
            'Generate a proposed code change for human review only.',
            'The proposal must be labeled PROPOSED CHANGE and FOR REVIEW.',
            'Use the incident, diagnosis, and real GitHub source context.',
            'Return exactly one minimal unified diff for exactly one file.',
            'The unified diff must apply cleanly to the supplied source content.',
            'Every context and removed line in the diff must be copied exactly from the supplied source content.',
            'Do not invent line numbers, duplicate overlapping hunks, or include a patch preview that is not a valid unified diff.',
            'Do not claim code was changed, a PR was created, deployment happened, the fix is verified, or production is safe.',
            'If a safe minimal proposal cannot be made, return {"status":"failed","error":"honest reason"}.',
            'Return only valid JSON.',
          ].join(' '),
        },
        {
          role: 'user',
          content: buildFixPrompt({ diagnosis, codeContext, incident, ragResults, previousError }),
        },
      ],
      temperature: 0,
      response_format: { type: 'json_object' },
    }),
  });

  const payload = await safeJson(response);
  if (!response.ok) {
    throw new FixProposalRequestError(payload?.error?.message || `LLM request failed with HTTP ${response.status}.`, 502);
  }

  const text = payload?.choices?.[0]?.message?.content;
  if (typeof text !== 'string' || !text.trim()) {
    throw new FixProposalRequestError('LLM returned no fix proposal content.', 502);
  }

  const parsed = parseJsonObject(text);
  return parsed;
}

function buildFixPrompt({ diagnosis, codeContext, incident, ragResults, previousError }) {
  const safeIncident = incident && typeof incident === 'object' ? incident : {};
  const safeDiagnosis = diagnosis && typeof diagnosis === 'object' ? diagnosis : {};
  const safeCode = codeContext && typeof codeContext === 'object' ? codeContext : {};
  const topRag = Array.isArray(ragResults) ? ragResults.slice(0, 5) : [];

  return JSON.stringify({
    task: 'Create a minimal explainable fix proposal for human review.',
    requiredOutput: {
      status: 'received',
      title: 'PROPOSED CHANGE - FOR REVIEW: concise title',
      summary: 'A short summary that says this is proposed, not applied.',
      affectedFiles: ['repository path'],
      diff: `--- a/${safeCode.path || 'path'}\n+++ b/${safeCode.path || 'path'}\n@@ -oldStart,oldCount +newStart,newCount @@\n exact context/removal/addition lines`,
      reasoning: 'Why this proposed change follows from diagnosis and source context.',
      confidence: 'integer 0-100',
      risk: 'LOW, MEDIUM, or HIGH plus short explanation',
      expectedOutcome: 'Expected behavior if reviewer accepts and tests the change.',
      validationPlan: ['manual or automated validation step'],
    },
    constraints: [
      'Proposal only. Do not claim GitHub was modified.',
      'Do not claim a PR was created.',
      'Do not claim deployment happened.',
      'Do not claim the fix is verified.',
      'Do not claim production is safe.',
      'Prefer the smallest realistic change to the affected file.',
      'The diff must target exactly githubCodeContext.path.',
      'Use only lines that exist in githubCodeContext.content as context or removals.',
      'Use one hunk when possible.',
      'Do not include duplicate alternatives, prose, Markdown fences, or incomplete hunks in diff.',
      'If validationError is present, correct that exact diff problem in the new response.',
    ],
    validationError: previousError || undefined,
    incident: safeIncident,
    diagnosis: safeDiagnosis,
    retrievedRagSources: topRag.map((result) => ({
      source: result.source,
      title: result.title,
      excerpt: result.excerpt,
      score: result.score,
    })),
    githubCodeContext: {
      source: safeCode.source,
      repository: safeCode.repository,
      path: safeCode.path,
      ref: safeCode.ref,
      commit: safeCode.commit,
      content: String(safeCode.content || '').slice(0, 14000),
    },
  });
}

function validateUnifiedDiff(source, diff, expectedPath) {
  if (!source) return 'GitHub source content is missing.';
  if (!expectedPath) return 'GitHub source path is missing.';
  try {
    const updated = applyUnifiedDiff(source, diff, expectedPath);
    if (updated === source) return 'Diff did not change the supplied source content.';
    return '';
  } catch (error) {
    return error.message || 'Diff did not apply to the supplied source content.';
  }
}

function applyUnifiedDiff(source, diff, expectedPath) {
  const original = splitLines(source);
  const hunks = parseHunks(diff, expectedPath);
  if (!hunks.length) throw new Error('Diff did not contain an applicable unified diff hunk.');

  const output = [];
  let originalIndex = 0;
  for (const hunk of hunks) {
    const hunkStart = hunk.oldStart - 1;
    if (hunkStart < originalIndex) throw new Error('Diff hunks overlap or are out of order.');
    output.push(...original.slice(originalIndex, hunkStart));
    originalIndex = hunkStart;
    for (const line of hunk.lines) {
      if (line.kind === 'context' || line.kind === 'remove') {
        if (original[originalIndex] !== line.text) {
          throw new Error('Diff context/removal lines do not match the supplied source content.');
        }
        if (line.kind === 'context') output.push(line.text);
        originalIndex += 1;
      } else if (line.kind === 'add') {
        output.push(line.text);
      }
    }
  }
  output.push(...original.slice(originalIndex));
  return joinLines(output, source.endsWith('\n'));
}

function parseHunks(diff, expectedPath) {
  const lines = String(diff || '').replace(/\r\n/g, '\n').split('\n');
  const hunks = [];
  let current = null;
  let touchedExpectedPath = false;
  for (const raw of lines) {
    if (raw.startsWith('+++ ')) {
      const path = raw.slice(4).trim().replace(/^b\//, '');
      if (path === expectedPath) touchedExpectedPath = true;
      continue;
    }
    const header = /^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(raw);
    if (header) {
      current = { oldStart: Number(header[1]), lines: [] };
      hunks.push(current);
      continue;
    }
    if (!current) continue;
    if (raw === '\\ No newline at end of file') continue;
    const marker = raw[0];
    const text = raw.slice(1);
    if (marker === ' ') current.lines.push({ kind: 'context', text });
    if (marker === '-') current.lines.push({ kind: 'remove', text });
    if (marker === '+') current.lines.push({ kind: 'add', text });
  }
  if (String(diff || '').includes('+++ ') && !touchedExpectedPath) {
    throw new Error('Diff targets a different file than the supplied GitHub source path.');
  }
  return hunks;
}

function splitLines(value) {
  const normalized = value.replace(/\r\n/g, '\n');
  const lines = normalized.split('\n');
  if (normalized.endsWith('\n')) lines.pop();
  return lines;
}

function joinLines(lines, trailingNewline) {
  return lines.join('\n') + (trailingNewline ? '\n' : '');
}

async function safeJson(response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

function parseJsonObject(text) {
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) throw new FixProposalRequestError('LLM fix proposal was not valid JSON.', 502);
    return JSON.parse(match[0]);
  }
}

function normalizeProposal(value, codeContext) {
  const proposal = value && typeof value === 'object' ? value : {};
  const diff = String(proposal.diff || '').trim();
  if (!diff) {
    return { status: 'failed', error: 'The model did not return a reviewable diff.' };
  }

  return {
    status: 'received',
    title: ensureReviewLabel(proposal.title || 'PROPOSED CHANGE - FOR REVIEW'),
    summary: ensureReviewLanguage(proposal.summary || 'This is a proposed change for human review. It has not been applied.'),
    affectedFiles: normalizeList(proposal.affectedFiles, codeContext?.path ? [codeContext.path] : []),
    diff,
    reasoning: ensureReviewLanguage(proposal.reasoning || 'The proposal follows from the supplied diagnosis and source context.'),
    confidence: clampConfidence(proposal.confidence),
    risk: normalizeRisk(proposal.risk),
    expectedOutcome: ensureReviewLanguage(proposal.expectedOutcome || 'Expected outcome requires reviewer approval and validation.'),
    validationPlan: normalizeList(proposal.validationPlan, [
      'Review the proposed diff.',
      'Run the affected component flow before any deployment decision.',
    ]),
  };
}

function ensureReviewLabel(value) {
  const text = String(value || '').trim();
  const upper = text.toUpperCase();
  if (upper.includes('PROPOSED CHANGE') && upper.includes('FOR REVIEW')) return text;
  return `PROPOSED CHANGE - FOR REVIEW: ${text || 'Candidate source change'}`;
}

function ensureReviewLanguage(value) {
  const text = String(value || '').trim();
  if (/proposed|for review|not applied/i.test(text)) return text;
  return `${text} This is a proposal for review and has not been applied.`;
}

function normalizeRisk(value) {
  const text = String(value || 'MEDIUM: Reviewer validation is required before any action.').trim();
  if (/^(LOW|MEDIUM|HIGH)\b/i.test(text)) return text.toUpperCase().replace(/^(LOW|MEDIUM|HIGH)/i, (match) => match.toUpperCase());
  return `MEDIUM: ${text}`;
}

function normalizeList(value, fallback) {
  const items = Array.isArray(value) ? value : [];
  const normalized = items.map((item) => String(item || '').trim()).filter(Boolean);
  return normalized.length ? normalized.slice(0, 8) : fallback;
}

function clampConfidence(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.max(0, Math.min(100, Math.round(number)));
}
