import http from 'http';

const GATEWAY_ORIGIN = 'http://127.0.0.1:9090';
const TIMEOUT_MS = 2000;

export function isLabModeEnabled() {
  return process.env.ONEOPS_LAB_MODE === 'true';
}

export async function switchGatewayToFailingGreen() {
  try {
    const before = await requestJson('GET', '/__oneops/status');
    const beforeActive = normalizeActive(before.body?.active);

    if (!beforeActive) {
      return unavailable('Gateway status did not include an active release.', {
        before: before.body,
      });
    }

    if (beforeActive === 'blue') {
      await requestJson('POST', '/__oneops/switch');
    }

    const after = await requestJson('GET', '/__oneops/status');
    const afterActive = normalizeActive(after.body?.active);
    const health = await requestJson('GET', '/health');
    const degradedGreen =
      afterActive === 'green' &&
      health.statusCode === 503 &&
      health.body?.status === 'degraded' &&
      health.body?.release === 'green';

    if (!degradedGreen) {
      return {
        status: 'verification_failed',
        mode: 'local-demo',
        switched: beforeActive === 'blue',
        beforeActive,
        afterActive,
        healthStatus: health.statusCode,
        message: 'Gateway did not verify as degraded Green.',
      };
    }

    return {
      status: beforeActive === 'blue' ? 'switched' : 'already_green',
      mode: 'local-demo',
      switched: beforeActive === 'blue',
      beforeActive,
      afterActive,
      healthStatus: health.statusCode,
      message:
        beforeActive === 'blue'
          ? 'Local gateway switched from Blue to degraded Green.'
          : 'Local gateway was already serving degraded Green.',
    };
  } catch (error) {
    return unavailable(error.message);
  }
}

function normalizeActive(value) {
  const active = String(value || '').toLowerCase();
  return active === 'blue' || active === 'green' ? active : '';
}

function unavailable(message, extra = {}) {
  return {
    status: 'unavailable',
    mode: 'local-demo',
    switched: false,
    message: `Local lab gateway unavailable: ${message}`,
    ...extra,
  };
}

function requestJson(method, path) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, GATEWAY_ORIGIN);
    const req = http.request(
      url,
      { method, timeout: TIMEOUT_MS },
      (res) => {
        let raw = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          let body = {};
          try {
            body = raw ? JSON.parse(raw) : {};
          } catch {
            body = { raw };
          }
          resolve({ statusCode: res.statusCode || 0, body });
        });
      },
    );

    req.on('timeout', () => {
      req.destroy(new Error(`${method} ${url.href} timed out`));
    });
    req.on('error', reject);
    req.end();
  });
}
