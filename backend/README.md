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
POST /api/incidents/rag-context
POST /api/incidents/diagnose
POST /api/incidents/propose-fix
POST /api/incidents/create-pr
POST /api/incidents/change-gate
POST /api/incidents/reproduce
POST /api/incidents/verify-fix
POST /api/incidents/approve-recover

## GitHub code context

The Ask-for-Code workflow can retrieve one read-only source file from GitHub through the backend. The phone never receives or stores the GitHub credential.

Required environment variables:

```bash
ONEOPS_GITHUB_TOKEN=github_pat_or_token
ONEOPS_GITHUB_REPOSITORY=Piyush4521/OneMeal
```

Optional:

```bash
ONEOPS_GITHUB_REF=main
ONEOPS_GITHUB_PATH_PREFIX=src/components
```

Endpoint:

```bash
POST /api/incidents/code-context
content-type: application/json

{
  "component": "GoogleTranslate",
  "path": "GoogleTranslate.tsx"
}
```

The backend maps `GoogleTranslate` to `GoogleTranslate.tsx`; with `ONEOPS_GITHUB_PATH_PREFIX=src/components`, the final GitHub path is `src/components/GoogleTranslate.tsx`. It returns decoded file content plus repository, ref, path, commit SHA, and source metadata. This endpoint is read-only.

## Local RAG context

The RAG retrieval layer searches a small local knowledge base under `backend/knowledge/`.
It uses incident text plus retrieved GitHub source text to return supporting runbooks and
previous verified incidents. It is retrieval only, not AI diagnosis.

```bash
POST /api/incidents/rag-context
content-type: application/json

{
  "query": "incident summary and evidence",
  "codeContext": "retrieved GitHub source"
}
```

## AI diagnosis

The diagnosis layer runs after incident capture, GitHub code context, and local RAG retrieval.
It calls a configurable OpenAI-compatible chat completions endpoint from the backend only.
Credentials are never sent to Flutter.

Required environment variables:

```bash
ONEOPS_LLM_ENDPOINT=https://api.example.com/v1/chat/completions
ONEOPS_LLM_MODEL=model-name
ONEOPS_LLM_API_KEY=provider_api_key
```

Endpoint:

```bash
POST /api/incidents/diagnose
content-type: application/json

{
  "incident": {},
  "codeContext": {},
  "ragResults": []
}
```

## Explainable fix proposal

The fix proposal layer runs after diagnosis. It asks the configured LLM for a proposed
change for human review only; it does not modify GitHub, create a PR, deploy, or verify
production safety.

```bash
POST /api/incidents/propose-fix
content-type: application/json

{
  "diagnosis": {},
  "codeContext": {},
  "incident": {},
  "ragResults": []
}
```

## GitHub review pull request

The PR creation endpoint turns an approved proposal into a review branch, one commit,
and an unmerged pull request. The GitHub token stays backend-only and is never returned
to the phone.

Minimum fine-grained token permissions for `Piyush4521/OneMeal`:

- Metadata: read
- Contents: read and write
- Pull requests: read and write
- Actions/workflows: read and write, only when OneOps must add the prototype CI workflow

Endpoint:

```bash
POST /api/incidents/create-pr
content-type: application/json

{
  "incident": {},
  "proposal": {},
  "codeContext": {}
}
```

The backend checks repository push permission before creating a branch, applies the
proposal diff against the retrieved source, verifies the base file still matches, and
fails instead of overwriting unexpected changes.

## Change gate

The change gate endpoint aggregates GitHub PR facts, GitHub Checks or commit status,
GitHub PR reviews, and OneOps prototype policy. It never merges a PR or deploys.

Prototype policy defaults:

```json
{
  "requirePrOpen": true,
  "requireCiPass": true,
  "requireHumanApproval": true,
  "requiredApprovals": 1,
  "allowMergeFromOneOps": false
}
```

Endpoint:

```bash
POST /api/incidents/change-gate
content-type: application/json

{
  "pr": { "prNumber": 1 },
  "incident": {},
  "policy": {}
}
```

For hackathon demos only, `policy.demoApproval=true` can satisfy the OneOps policy
layer when a second reviewer is unavailable. The response labels that source as
OneOps demo approval and not a GitHub approval.
