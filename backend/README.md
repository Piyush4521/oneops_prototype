# OneOps Backend

This backend implements the real prototype workflow state machine and calls the Docker sandbox for reproduction. It does not mark reproduction as successful when Docker is unavailable.

## Run from repository root

```bash
cd backend
node src/server.js
```

Set `ONEOPS_COMPOSE` if the compose file is elsewhere. Default is `../lab/docker-compose.yml` relative to `backend/`.

## API
GET  /api/state
POST /api/lab/inject-failure
POST /api/incidents/capture
POST /api/incidents/investigate
POST /api/incidents/code-context
POST /api/incidents/reproduce
POST /api/incidents/verify-fix
POST /api/incidents/approve-recover

## GitHub code context

The Ask-for-Code workflow can retrieve one read-only source file from GitHub through the backend. The phone never receives or stores the GitHub credential.

Required environment variables:

```bash
ONEOPS_GITHUB_TOKEN=github_pat_or_token_with_repo_read_access
ONEOPS_GITHUB_REPOSITORY=owner/repository
```

Optional:

```bash
ONEOPS_GITHUB_REF=main
ONEOPS_GITHUB_PATH_PREFIX=lib/src
```

Endpoint:

```bash
POST /api/incidents/code-context
content-type: application/json

{
  "component": "RequestMiddleware",
  "path": "request_middleware.dart"
}
```

The backend maps `RequestMiddleware` to `request_middleware.dart` for the MVP and returns decoded file content plus repository, ref, path, commit SHA, and source metadata. It does not create PRs or write to GitHub.
