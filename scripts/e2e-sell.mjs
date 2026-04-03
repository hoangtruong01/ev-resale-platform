import assert from "node:assert/strict";

const baseUrl = process.env.FE_BASE_URL ?? "http://localhost:3001/be";
const email = process.env.E2E_EMAIL ?? "john@example.com";
const password = process.env.E2E_PASSWORD ?? "password123";

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const rawBody = await response.text();

  let parsed;
  try {
    parsed = rawBody ? JSON.parse(rawBody) : {};
  } catch (error) {
    console.error("Failed to parse JSON", {
      url,
      status: response.status,
      rawBody,
    });
    throw error;
  }

  return { response, body: parsed };
}

function assertOk(response, body, context) {
  if (!response.ok) {
    console.error(`${context} failed`, { status: response.status, body });
    throw new Error(`${context} failed with status ${response.status}`);
  }
}

async function run() {
  console.log("→ Logging in through FE proxy", baseUrl);
  const { response: loginRes, body: loginBody } = await fetchJson(
    `${baseUrl}/auth/login`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password }),
    }
  );
  assertOk(loginRes, loginBody, "Login");

  const token = loginBody.accessToken;
  assert.ok(token, "Missing access token");

  const vehiclePayload = {
    name: `E2E QA VinFast ${Date.now()}`,
    brand: "VinFast",
    model: "VF8",
    year: 2024,
    price: 980000000,
    mileage: 12000,
    condition: "Like new",
    description: "Xe chạy kiểm thử e2e, thông tin đầy đủ, không spam.",
    images: ["/uploads/listings/e2e-vf8-1.jpg"],
    location: "Hà Nội",
    status: "AVAILABLE",
  };

  console.log("→ Submitting vehicle listing", vehiclePayload.name);
  const { response: createRes, body: createBody } = await fetchJson(
    `${baseUrl}/vehicles`,
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(vehiclePayload),
    }
  );
  assertOk(createRes, createBody, "Create vehicle");

  assert.equal(
    createBody.approvalStatus,
    "PENDING",
    "Vehicle should wait for admin approval"
  );
  assert.equal(
    createBody.isActive,
    true,
    "Vehicle should remain active for moderation"
  );
  assert.ok(createBody.spamCheckedAt, "Spam check timestamp missing");

  const summary = {
    vehicleId: createBody.id,
    approvalStatus: createBody.approvalStatus,
    isSpamSuspicious: createBody.isSpamSuspicious,
    spamScore: createBody.spamScore,
    spamReasons: createBody.spamReasons,
  };

  console.log("✅ E2E sell flow success", JSON.stringify(summary, null, 2));
}

run().catch((error) => {
  console.error("❌ E2E sell flow failed", error);
  process.exitCode = 1;
});
