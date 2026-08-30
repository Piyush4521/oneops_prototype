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
  const url = `${GITHUB_API}/repos/${config.repository}/contents/${encodedPath}?ref=${encodeURIComponent(config.ref)}`;
  const response = await fetch(url, {
    headers: {
      accept: 'application/vnd.github+json',
      authorization: `Bearer ${config.token}`,
      'user-agent': 'oneops-prototype',
      'x-github-api-version': '2022-11-28',
    },
  });

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
  const url = `${GITHUB_API}/repos/${config.repository}/commits?sha=${encodeURIComponent(config.ref)}&path=${encodeURIComponent(path)}&per_page=1`;
  try {
    const response = await fetch(url, {
      headers: {
        accept: 'application/vnd.github+json',
        authorization: `Bearer ${config.token}`,
        'user-agent': 'oneops-prototype',
        'x-github-api-version': '2022-11-28',
      },
    });
    if (!response.ok) return '';
    const commits = await response.json();
    return Array.isArray(commits) && commits[0]?.sha ? commits[0].sha : '';
  } catch {
    return '';
  }
}
