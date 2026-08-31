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
            'Do not claim code was changed, a PR was created, deployment happened, the fix is verified, or production is safe.',
            'If a safe minimal proposal cannot be made, return {"status":"failed","error":"honest reason"}.',
            'Return only valid JSON.',
          ].join(' '),
        },
        {
          role: 'user',
          content: buildFixPrompt({ diagnosis, codeContext, incident, ragResults }),
        },
      ],
      temperature: 0.2,
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
  if (parsed?.status === 'failed') {
    return { status: 'failed', error: String(parsed.error || 'The model could not propose a safe reviewable change.') };
  }
  return normalizeProposal(parsed, codeContext);
}

function buildFixPrompt({ diagnosis, codeContext, incident, ragResults }) {
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
      diff: 'unified diff or focused patch preview',
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
    ],
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
