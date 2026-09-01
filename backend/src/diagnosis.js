export class DiagnosisConfigError extends Error {}
export class DiagnosisRequestError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.status = status;
  }
}

export function getDiagnosisConfig() {
  return {
    endpoint: process.env.ONEOPS_LLM_ENDPOINT || '',
    apiKey: process.env.ONEOPS_LLM_API_KEY || process.env.OPENAI_API_KEY || '',
    model: process.env.ONEOPS_LLM_MODEL || '',
  };
}

export async function diagnoseIncident({ incident, codeContext, ragResults } = {}) {
  const config = getDiagnosisConfig();
  if (!config.endpoint) throw new DiagnosisConfigError('LLM endpoint is not configured.');
  if (!config.apiKey) throw new DiagnosisConfigError('LLM API key is not configured.');
  if (!config.model) throw new DiagnosisConfigError('LLM model is not configured.');

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
            'You are the OneOps AI diagnosis layer.',
            'Use only the supplied incident, GitHub code context, and retrieved knowledge.',
            'Explicitly distinguish OBSERVED facts, RETRIEVED knowledge, INFERRED conclusions, and RECOMMENDED next action.',
            'Do not claim production access, deployment, verified fixes, final production decisions, or approval bypass.',
            'Return only valid JSON matching the requested schema.',
          ].join(' '),
        },
        {
          role: 'user',
          content: buildDiagnosisPrompt({ incident, codeContext, ragResults }),
        },
      ],
      temperature: 0.2,
      response_format: { type: 'json_object' },
    }),
  });

  const payload = await safeJson(response);
  if (!response.ok) {
    throw new DiagnosisRequestError(payload?.error?.message || `LLM request failed with HTTP ${response.status}.`, 502);
  }

  const text = payload?.choices?.[0]?.message?.content;
  if (typeof text !== 'string' || !text.trim()) {
    throw new DiagnosisRequestError('LLM returned no diagnosis content.', 502);
  }

  return normalizeDiagnosis(parseJsonObject(text));
}

function buildDiagnosisPrompt({ incident, codeContext, ragResults }) {
  const safeIncident = incident && typeof incident === 'object' ? incident : {};
  const evidence = Array.isArray(safeIncident.evidence) ? safeIncident.evidence : [];
  const history = Array.isArray(safeIncident.history) ? safeIncident.history : [];
  const topRag = Array.isArray(ragResults) ? ragResults.slice(0, 5) : [];

  return JSON.stringify({
    task: 'Diagnose the most likely engineering root cause for this incident.',
    requiredOutput: {
      status: 'received',
      rootCause: 'INFERRED: concise most likely root cause',
      confidence: 'integer 0-100',
      evidence: [
        'OBSERVED: cite incident evidence',
        'RETRIEVED: cite RAG source or GitHub code context',
      ],
      alternativeCause: 'INFERRED: plausible alternative explanation',
      risk: 'INFERRED: risk if the next action is wrong or incomplete',
      recommendation: 'RECOMMENDED: smallest next engineering action; no production approval bypass',
      affectedFiles: ['repository path only'],
    },
    constraints: [
      'Use the Incident Capsule, GitHub source, and RAG results.',
      'Do not present inference as fact.',
      'Do not claim a fix has been verified.',
      'Do not claim anything was deployed.',
      'Do not make final production decisions.',
    ],
    incident: {
      id: safeIncident.id,
      status: safeIncident.status,
      severity: safeIncident.severity,
      summary: safeIncident.summary,
      confidence: safeIncident.confidence,
      evidence,
      hypothesis: safeIncident.hypothesis,
      experiment: safeIncident.experiment,
      history,
    },
    interactionTrace: history,
    deploymentContext: {
      observed: evidence.filter((item) => /deploy|green|blue|ci|build|runtime|health/i.test(String(item))),
      hypothesis: safeIncident.hypothesis,
      recommendedExperiment: safeIncident.experiment,
    },
    githubCodeContext: {
      source: codeContext?.source,
      repository: codeContext?.repository,
      path: codeContext?.path,
      ref: codeContext?.ref,
      commit: codeContext?.commit,
      content: String(codeContext?.content || '').slice(0, 12000),
    },
    retrievedRagSources: topRag.map((result) => ({
      source: result.source,
      title: result.title,
      excerpt: result.excerpt,
      score: result.score,
    })),
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
    if (!match) throw new DiagnosisRequestError('LLM diagnosis was not valid JSON.', 502);
    return JSON.parse(match[0]);
  }
}

function normalizeDiagnosis(value) {
  const diagnosis = value && typeof value === 'object' ? value : {};
  return {
    status: 'received',
    rootCause: labeledText(diagnosis.rootCause, 'INFERRED', 'Most likely cause could not be determined from the supplied context.'),
    confidence: clampConfidence(diagnosis.confidence),
    evidence: normalizeEvidence(diagnosis.evidence),
    alternativeCause: labeledText(diagnosis.alternativeCause, 'INFERRED', 'No alternative cause was supplied.'),
    risk: labeledText(diagnosis.risk, 'INFERRED', 'Risk was not assessed.'),
    recommendation: labeledText(diagnosis.recommendation, 'RECOMMENDED', 'Run a narrow engineering review before any recovery action.'),
    affectedFiles: normalizeAffectedFiles(diagnosis.affectedFiles),
  };
}

function labeledText(value, label, fallback) {
  const text = String(value || fallback).trim();
  return text.toUpperCase().startsWith(`${label}:`) ? text : `${label}: ${text}`;
}

function normalizeEvidence(value) {
  const items = Array.isArray(value) ? value : [];
  const normalized = items
    .map((item) => String(item || '').trim())
    .filter(Boolean)
    .map((item) => {
      if (/^(OBSERVED|RETRIEVED|INFERRED):/i.test(item)) return item;
      return `OBSERVED: ${item}`;
    });
  return normalized.length ? normalized.slice(0, 6) : ['OBSERVED: No supporting evidence was supplied by the model.'];
}

function normalizeAffectedFiles(value) {
  const items = Array.isArray(value) ? value : [];
  const files = items.map((item) => String(item || '').trim()).filter(Boolean);
  return files.length ? files.slice(0, 5) : [];
}

function clampConfidence(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.max(0, Math.min(100, Math.round(number)));
}
