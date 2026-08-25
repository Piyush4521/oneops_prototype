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
POST /api/incidents/reproduce
POST /api/incidents/verify-fix
POST /api/incidents/approve-recover
