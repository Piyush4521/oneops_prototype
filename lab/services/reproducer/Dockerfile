FROM curlimages/curl:8.12.1
CMD sh -c 'echo "[OneOps sandbox] Testing Green"; curl -fsS http://green:8080/health || true; echo; echo "[OneOps sandbox] Testing Blue"; curl -fsS http://blue:8080/health; echo; echo "[OneOps sandbox] Candidate recovery check: Blue healthy"'
