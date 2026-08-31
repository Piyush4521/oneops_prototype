const GITHUB_API = 'https://api.github.com';

const componentPathMap = {
  GoogleTranslate: 'GoogleTranslate.tsx',
};

export class GitHubConfigError extends Error {}
export class GitHubRequestError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.status = status;
  }
}

export function getCodeContextConfig() {
  return {
    token: process.env.ONEOPS_GITHUB_TOKEN,
    repository: process.env.ONEOPS_GITHUB_REPOSITORY,
    ref: process.env.ONEOPS_GITHUB_REF || 'main',
    pathPrefix: process.env.ONEOPS_GITHUB_PATH_PREFIX || '',
  };
}

export function resolveRequestedPath(component, requestedPath, config = getCodeContextConfig()) {
  const mapped = componentPathMap[component] || requestedPath;
  if (!mapped) throw new GitHubRequestError('No requested file mapping exists for this component.', 400);
  const cleanPrefix = config.pathPrefix.replace(/^\/+|\/+$/g, '');
  const cleanPath = mapped.replace(/^\/+/g, '');
  return cleanPrefix ? `${cleanPrefix}/${cleanPath}` : cleanPath;
}

export async function fetchCodeContext({ component, requestedPath }) {
  const config = getCodeContextConfig();
  if (!config.token) throw new GitHubConfigError('GitHub token is not configured.');
  if (!config.repository) throw new GitHubConfigError('GitHub repository is not configured.');

  const path = resolveRequestedPath(component, requestedPath, config);
  const encodedPath = path.split('/').map(encodeURIComponent).join('/');
  const response = await githubFetch(config, `/contents/${encodedPath}?ref=${encodeURIComponent(config.ref)}`);

  if (response.status === 401 || response.status === 403) {
    throw new GitHubRequestError('GitHub credential is missing required read access.', 502);
  }
  if (response.status === 404) {
    throw new GitHubRequestError('Requested code file was not found in the configured repository/ref.', 404);
  }
  if (!response.ok) {
    throw new GitHubRequestError(`GitHub file retrieval failed with HTTP ${response.status}.`, 502);
  }

  const payload = await response.json();
  if (payload.type !== 'file' || typeof payload.content !== 'string') {
    throw new GitHubRequestError('Configured GitHub path did not resolve to a readable file.', 422);
  }

  const commit = await fetchLatestCommitSha(config, path);
  const content = Buffer.from(payload.content.replace(/\n/g, ''), 'base64').toString('utf8');
  return {
    status: 'received',
    repository: config.repository,
    path: payload.path || path,
    ref: config.ref,
    commit: commit || payload.sha || '',
    content,
    source: 'GitHub',
  };
}

async function fetchLatestCommitSha(config, path) {
  try {
    const response = await githubFetch(
      config,
      `/commits?sha=${encodeURIComponent(config.ref)}&path=${encodeURIComponent(path)}&per_page=1`,
    );
    if (!response.ok) return '';
    const commits = await response.json();
    return Array.isArray(commits) && commits[0]?.sha ? commits[0].sha : '';
  } catch {
    return '';
  }
}

export async function createPullRequestFromProposal({ incident, proposal, codeContext }) {
  const config = getCodeContextConfig();
  if (!config.token) throw new GitHubConfigError('GitHub token is not configured.');
  if (!config.repository) throw new GitHubConfigError('GitHub repository is not configured.');
  if (!incident?.id) throw new GitHubRequestError('Incident is required to create a review branch.', 400);
  if (!proposal?.title || !proposal?.diff) {
    throw new GitHubRequestError('A fix proposal with a diff is required to create a review branch.', 400);
  }
  if (!codeContext?.path || !codeContext?.content) {
    throw new GitHubRequestError('GitHub code context is required before creating a review branch.', 400);
  }
  if (codeContext.repository && codeContext.repository !== config.repository) {
    throw new GitHubRequestError('GitHub code context repository does not match the configured target repository.', 422);
  }

  const base = 'main';
  const path = codeContext.path;
  const baseContent = await fetchFileContent(config, path, base);
  const latestCommit = await fetchLatestCommitSha(config, path);
  if (codeContext.commit && latestCommit && codeContext.commit !== latestCommit) {
    throw new GitHubRequestError('GitHub source changed after code context retrieval. Refresh code context before creating a PR.', 409);
  }
  if (baseContent.content !== codeContext.content) {
    throw new GitHubRequestError('GitHub source changed after code context retrieval. Refresh code context before creating a PR.', 409);
  }

  const updatedContent = applyUnifiedDiff(baseContent.content, proposal.diff, path);
  if (updatedContent === baseContent.content) {
    throw new GitHubRequestError('Proposed diff did not change the retrieved source file.', 422);
  }

  await assertWritePermission(config);
  const baseRef = await requestJson(config, `/git/ref/heads/${encodeURIComponent(base)}`);
  const branch = await createAvailableBranch(config, safeBranchBase(incident.id), baseRef.object?.sha);
  const commitMessage = `fix: ${proposal.title}`.slice(0, 200);
  const commitResponse = await requestJson(config, `/contents/${encodeGitPath(path)}`, {
    method: 'PUT',
    body: {
      message: commitMessage,
      content: Buffer.from(updatedContent, 'utf8').toString('base64'),
      sha: baseContent.sha,
      branch,
    },
  });
  const commit = commitResponse.commit?.sha;
  if (!commit) throw new GitHubRequestError('GitHub did not return a commit SHA for the proposed change.', 502);

  await verifySingleFileCommit(config, commit, path);
  const pr = await requestJson(config, '/pulls', {
    method: 'POST',
    body: {
      title: `OneOps: ${proposal.title}`.slice(0, 200),
      head: branch,
      base,
      body: buildPullRequestBody({ incident, proposal, codeContext }),
      maintainer_can_modify: true,
    },
  });
  const checkedPr = await requestJson(config, `/pulls/${pr.number}`);
  if (checkedPr.base?.ref !== base || checkedPr.merged === true) {
    throw new GitHubRequestError('Created pull request did not satisfy OneOps review safety checks.', 502);
  }

  return {
    status: 'created',
    repository: config.repository,
    branch,
    commit,
    prNumber: pr.number,
    prUrl: pr.html_url,
    base,
  };
}

export async function fetchPullRequestGovernance({ prNumber }) {
  const config = getCodeContextConfig();
  if (!config.token) throw new GitHubConfigError('GitHub token is not configured.');
  if (!config.repository) throw new GitHubConfigError('GitHub repository is not configured.');
  const number = Number(prNumber);
  if (!Number.isInteger(number) || number <= 0) {
    throw new GitHubRequestError('A pull request number is required.', 400);
  }

  const pr = await requestJson(config, `/pulls/${number}`);
  const reviews = await requestJson(config, `/pulls/${number}/reviews?per_page=100`);
  const status = await requestJson(config, `/commits/${encodeURIComponent(pr.head.sha)}/status`);
  const checks = await requestJson(config, `/commits/${encodeURIComponent(pr.head.sha)}/check-runs?per_page=100`);
  const files = await requestJson(config, `/pulls/${number}/files?per_page=100`);
  const review = summarizeReviews(reviews);
  const ci = summarizeCi({ status, checks });

  return {
    prNumber: pr.number,
    title: pr.title,
    state: pr.state,
    merged: pr.merged === true,
    baseBranch: pr.base?.ref || '',
    headBranch: pr.head?.ref || '',
    url: pr.html_url,
    latestCommitSha: pr.head?.sha || '',
    author: pr.user?.login || '',
    reviewStatus: review.status,
    approvingReviews: review.approvingReviews,
    changesRequested: review.changesRequested,
    reviewPending: review.reviewPending,
    ciStatus: ci.status,
    ciSource: ci.source,
    ciDetails: ci.details,
    changedFiles: Array.isArray(files) ? files.map((file) => file.filename) : [],
    source: 'GitHub',
  };
}

function summarizeReviews(reviews) {
  const latestByUser = new Map();
  for (const review of Array.isArray(reviews) ? reviews : []) {
    const user = review.user?.login;
    if (!user) continue;
    latestByUser.set(user, review.state);
  }
  const states = [...latestByUser.values()];
  const approvingReviews = states.filter((state) => state === 'APPROVED').length;
  const changesRequested = states.some((state) => state === 'CHANGES_REQUESTED');
  const reviewPending = states.length === 0 || states.some((state) => state === 'COMMENTED' || state === 'PENDING');
  const status = changesRequested ? 'changes_requested' : approvingReviews > 0 ? 'approved' : 'pending';
  return { status, approvingReviews, changesRequested, reviewPending };
}

function summarizeCi({ status, checks }) {
  const statusStates = Array.isArray(status?.statuses) ? status.statuses.map((item) => item.state) : [];
  const checkRuns = Array.isArray(checks?.check_runs) ? checks.check_runs : [];
  const checkStates = checkRuns.map((run) => run.status === 'completed' ? run.conclusion : run.status);
  const allStates = [...statusStates, ...checkStates].filter(Boolean);
  if (!allStates.length) return { status: 'unknown', source: 'none', details: [] };
  if (allStates.some((state) => ['failure', 'error', 'cancelled', 'timed_out', 'action_required'].includes(state))) {
    return { status: 'failed', source: ciSource(statusStates, checkRuns), details: ciDetails(statusStates, checkRuns) };
  }
  if (allStates.some((state) => ['queued', 'requested', 'waiting', 'pending', 'in_progress'].includes(state))) {
    return { status: 'pending', source: ciSource(statusStates, checkRuns), details: ciDetails(statusStates, checkRuns) };
  }
  if (allStates.every((state) => ['success', 'neutral', 'skipped'].includes(state))) {
    return { status: 'passed', source: ciSource(statusStates, checkRuns), details: ciDetails(statusStates, checkRuns) };
  }
  return { status: 'unknown', source: ciSource(statusStates, checkRuns), details: ciDetails(statusStates, checkRuns) };
}

function ciSource(statusStates, checkRuns) {
  if (checkRuns.length) return 'GitHub Checks';
  if (statusStates.length) return 'GitHub commit statuses';
  return 'none';
}

function ciDetails(statusStates, checkRuns) {
  if (checkRuns.length) {
    return checkRuns.map((run) => ({
      name: run.name,
      status: run.status,
      conclusion: run.conclusion,
      url: run.html_url,
    }));
  }
  return statusStates.map((state) => ({ name: 'combined status', status: state, conclusion: state }));
}

async function githubFetch(config, route, options = {}) {
  const response = await fetch(`${GITHUB_API}/repos/${config.repository}${route}`, {
    method: options.method || 'GET',
    headers: {
      accept: 'application/vnd.github+json',
      authorization: `Bearer ${config.token}`,
      'content-type': 'application/json',
      'user-agent': 'oneops-prototype',
      'x-github-api-version': '2022-11-28',
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  return response;
}

async function requestJson(config, route, options = {}) {
  const response = await githubFetch(config, route, options);
  const text = await response.text();
  const payload = text ? JSON.parse(text) : {};
  if (response.status === 401 || response.status === 403) {
    throw new GitHubRequestError('GitHub credential is missing required write access.', 502);
  }
  if (!response.ok) {
    const message = payload?.message ? ` GitHub says: ${payload.message}` : '';
    throw new GitHubRequestError(`GitHub request failed with HTTP ${response.status}.${message}`, 502);
  }
  return payload;
}

async function fetchFileContent(config, path, ref) {
  const payload = await requestJson(config, `/contents/${encodeGitPath(path)}?ref=${encodeURIComponent(ref)}`);
  if (payload.type !== 'file' || typeof payload.content !== 'string' || !payload.sha) {
    throw new GitHubRequestError('Configured GitHub path did not resolve to a writable file.', 422);
  }
  return {
    sha: payload.sha,
    content: Buffer.from(payload.content.replace(/\n/g, ''), 'base64').toString('utf8'),
  };
}

async function assertWritePermission(config) {
  const repo = await requestJson(config, '');
  if (repo.permissions && repo.permissions.push !== true && repo.permissions.admin !== true) {
    throw new GitHubRequestError('GitHub credential can read the repository but cannot push review branches.', 502);
  }
}

async function createAvailableBranch(config, branchBase, baseSha) {
  if (!baseSha) throw new GitHubRequestError('Could not resolve the base branch SHA.', 502);
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const branch = attempt === 0 ? branchBase : `${branchBase}-${attempt + 1}`;
    const exists = await branchExists(config, branch);
    if (exists) continue;
    await requestJson(config, '/git/refs', {
      method: 'POST',
      body: { ref: `refs/heads/${branch}`, sha: baseSha },
    });
    return branch;
  }
  throw new GitHubRequestError('Could not create a non-conflicting OneOps review branch.', 409);
}

async function branchExists(config, branch) {
  const response = await githubFetch(config, `/git/ref/heads/${encodeURIComponent(branch)}`);
  if (response.status === 404) return false;
  if (response.status === 401 || response.status === 403) {
    throw new GitHubRequestError('GitHub credential is missing required write access.', 502);
  }
  if (!response.ok) {
    throw new GitHubRequestError(`GitHub branch lookup failed with HTTP ${response.status}.`, 502);
  }
  return true;
}

async function verifySingleFileCommit(config, commit, path) {
  const payload = await requestJson(config, `/commits/${encodeURIComponent(commit)}`);
  const files = Array.isArray(payload.files) ? payload.files : [];
  if (files.length !== 1 || files[0].filename !== path) {
    throw new GitHubRequestError('Created commit changed files outside the proposed OneOps source file.', 502);
  }
}

function applyUnifiedDiff(source, diff, expectedPath) {
  const original = splitLines(source);
  const hunks = parseHunks(diff, expectedPath);
  if (!hunks.length) throw new GitHubRequestError('Proposed diff did not contain an applicable unified diff hunk.', 422);

  const output = [];
  let originalIndex = 0;
  for (const hunk of hunks) {
    const hunkStart = hunk.oldStart - 1;
    if (hunkStart < originalIndex) throw new GitHubRequestError('Proposed diff hunks overlap or are out of order.', 422);
    output.push(...original.slice(originalIndex, hunkStart));
    originalIndex = hunkStart;
    for (const line of hunk.lines) {
      if (line.kind === 'context' || line.kind === 'remove') {
        if (original[originalIndex] !== line.text) {
          throw new GitHubRequestError('Proposed diff does not match the retrieved GitHub source.', 409);
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
  const lines = diff.replace(/\r\n/g, '\n').split('\n');
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
  if (diff.includes('+++ ') && !touchedExpectedPath) {
    throw new GitHubRequestError('Proposed diff targets a different file than the retrieved GitHub source.', 422);
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

function encodeGitPath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
}

function safeBranchBase(incidentId) {
  const suffix = incidentId
    .toString()
    .trim()
    .toLowerCase()
    .replace(/^inc-?/, '')
    .replace(/[^a-z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'incident';
  return `oneops/inc-${suffix}`;
}

function buildPullRequestBody({ incident, proposal, codeContext }) {
  const evidence = Array.isArray(incident.evidence) ? incident.evidence.slice(0, 6) : [];
  const validation = Array.isArray(proposal.validationPlan) ? proposal.validationPlan : [];
  return [
    '## OneOps Proposed Change',
    '',
    'This pull request was opened by OneOps for normal human review. It is not merged, deployed, verified in production, or approved automatically.',
    '',
    `- Incident ID: ${incident.id}`,
    `- Summary: ${incident.summary || 'No summary provided.'}`,
    `- Root cause: ${proposal.rootCause || proposal.summary || 'See proposal summary.'}`,
    `- Proposed change: ${proposal.summary || proposal.title}`,
    `- Affected file: ${codeContext.path}`,
    `- Confidence: ${proposal.confidence ?? 0}%`,
    `- Risk: ${proposal.risk || 'MEDIUM'}`,
    '',
    '## Evidence Summary',
    '',
    ...(evidence.length ? evidence.map((item) => `- ${item}`) : ['- No evidence supplied.']),
    '',
    '## Reasoning',
    '',
    proposal.reasoning || 'No reasoning supplied.',
    '',
    '## Validation Plan',
    '',
    ...(validation.length ? validation.map((item) => `- [ ] ${item}`) : ['- [ ] Review proposed diff.']),
    '',
    '## Review Requirement',
    '',
    'Requires the repository normal review, test, and merge process. OneOps did not bypass branch protection or approve deployment.',
  ].join('\n');
}
