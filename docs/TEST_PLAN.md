# OneOps Prototype Test Plan

## P0: workflow safety
- Verification cannot run before reproduction.
- Recovery cannot run before explicit approval state.
- A Docker sandbox failure does not become VERIFIED_FIX_READY.
- Repeated recovery requests are rejected after the incident is already recovered.

## P0: hero incident
1. Start Blue and Green services.
2. Confirm Blue /health returns healthy.
3. Confirm Green /health returns 503.
4. Inject incident.
5. Investigate.
6. Reproduce through Docker.
7. Verify.
8. Approve and recover.
9. Confirm final state and MTTR.

## P1: phone
- Camera capture reaches backend.
- Voice input works.
- Physical phone reaches laptop backend over LAN.
- Loading/error states are visible.

## P1: negative cases
- Stop Docker before reproduce: app must show sandbox unavailable.
- Stop backend: app must show backend unavailable.
- Attempt verify too early: blocked.
- Attempt approve too early: blocked.
- Repeat approve after recovery: blocked.

## P2: security side layer
- /login rate limit returns 429 after threshold.
- Gateway status exposes active release.
- Security evidence can be added to the Incident Capsule in the next iteration.
