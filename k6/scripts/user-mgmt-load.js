// k6 load test for user_mgmt_service (Aufgabe 2 Chaos Testing).
//
// Ramps traffic up to 60 VUs, holds, then ramps down. Two scenarios in
// parallel: /actuator/health (cheap) and /users/register (writes → CPU +
// DB load → HPA reacts). Exercises Request Rate, Response Time and Error
// Rate — the same metrics surfaced by the user-mgmt Grafana dashboard.
//
// Run inside the cluster via manifests/k6-job.yaml. TARGET_BASE_URL defaults
// to the ClusterIP service; override via env if you point at a different
// release.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

const BASE_URL = __ENV.TARGET_BASE_URL || 'http://user-mgmt-prod-user-mgmt-backend.user-mgmt-prod.svc.cluster.local:8080';

const registerDuration = new Trend('register_duration', true);
const registerErrors = new Counter('register_errors');

export const options = {
  discardResponseBodies: false,
  thresholds: {
    // Fail the run if error budget exceeded — mirrors PrometheusRule.
    'http_req_failed{scenario:register}': ['rate<0.10'],
    'http_req_duration{scenario:register}': ['p(95)<1500'],
    'http_req_failed{scenario:health}': ['rate<0.01'],
  },
  scenarios: {
    health: {
      executor: 'constant-vus',
      exec: 'health',
      vus: 5,
      duration: '10m',
      tags: { scenario: 'health' },
    },
    register: {
      executor: 'ramping-vus',
      exec: 'register',
      startVUs: 1,
      stages: [
        { duration: '1m',  target: 10 },
        { duration: '2m',  target: 30 },
        { duration: '3m',  target: 60 },  // hold above HPA CPU target
        { duration: '2m',  target: 60 },
        { duration: '2m',  target: 0 },   // ramp down → HPA should shrink
      ],
      tags: { scenario: 'register' },
    },
  },
};

export function health() {
  const res = http.get(`${BASE_URL}/actuator/health`);
  check(res, { 'health 200': (r) => r.status === 200 });
  sleep(1);
}

export function register() {
  const suffix = randomString(10);
  const payload = JSON.stringify({
    firstName: `Load`,
    lastName: `Test-${suffix}`,
    email: `loadtest-${suffix}@example.com`,
    password: 'P@ssw0rd!Test123',
  });
  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { scenario: 'register' },
  };
  const res = http.post(`${BASE_URL}/users/register`, payload, params);
  registerDuration.add(res.timings.duration);
  const ok = check(res, {
    'register 2xx': (r) => r.status >= 200 && r.status < 300,
  });
  if (!ok) {
    registerErrors.add(1);
  }
  sleep(Math.random() * 0.3);
}
