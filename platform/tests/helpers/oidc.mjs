// Loopback-only identity provider for automated protocol tests. Never used by the app entrypoint.
import { createServer } from "node:http";
import { createHash, randomUUID } from "node:crypto";
import { generateKeyPair, exportJWK, SignJWT } from "jose";
import * as oidc from "openid-client";
import { createAuthingProvider } from "../../apps/api/dist/modules/auth/authing.js";

export async function mockOidc() {
  const key = await generateKeyPair("RS256");
  const wrongKey = await generateKeyPair("RS256");
  const jwk = {
    ...(await exportJWK(key.publicKey)),
    kid: "test-key",
    alg: "RS256",
    use: "sig",
  };
  const codes = new Map();
  let issuer,
    tokenCalls = 0;
  function makeCode(authUrl, subject = "student", claims = {}) {
    const query = new URL(authUrl).searchParams,
      code = randomUUID();
    codes.set(code, {
      subject,
      claims,
      nonce: query.get("nonce"),
      challenge: query.get("code_challenge"),
      redirect: query.get("redirect_uri"),
    });
    const callback = new URL(query.get("redirect_uri"));
    callback.searchParams.set("code", code);
    callback.searchParams.set("state", query.get("state"));
    return callback;
  }
  const server = createServer(async (request, response) => {
    const url = new URL(request.url, "http://localhost");
    response.setHeader("Cache-Control", "no-store");
    const send = (code, value) => {
      response.writeHead(code, { "Content-Type": "application/json" });
      response.end(JSON.stringify(value));
    };
    if (url.pathname === "/oidc/.well-known/openid-configuration")
      return send(200, {
        issuer,
        authorization_endpoint: issuer + "/auth",
        token_endpoint: issuer + "/token",
        jwks_uri: issuer + "/jwks",
        response_types_supported: ["code"],
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["RS256"],
        token_endpoint_auth_methods_supported: ["client_secret_post"],
        code_challenge_methods_supported: ["S256"],
      });
    if (url.pathname === "/oidc/jwks") return send(200, { keys: [jwk] });
    if (url.pathname === "/oidc/auth") {
      // Explicitly labelled test-only screen supports browser acceptance without any external credentials.
      const safe = url.searchParams
        .toString()
        .replaceAll("&", "&amp;")
        .replaceAll('"', "&quot;");
      response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      response.end(
        `<h1>仅测试：模拟身份服务</h1><p>这不是 Authing 正式服务。</p><a href="/choose?${safe}&test_subject=student">测试同学登录</a><br><a href="/choose?${safe}&test_subject=student-b">测试同学B登录</a><br><a href="/choose?${safe}&test_subject=operator">测试运营登录</a>`,
      );
      return;
    }
    if (url.pathname === "/choose") {
      const callback = makeCode(
        issuer + "/auth?" + url.searchParams,
        url.searchParams.get("test_subject"),
      );
      response.writeHead(302, { Location: callback.href });
      response.end();
      return;
    }
    if (url.pathname === "/login/profile/logout") {
      response.writeHead(302, {
        Location: url.searchParams.get("redirect_uri"),
      });
      response.end();
      return;
    }
    if (url.pathname === "/oidc/token") {
      tokenCalls++;
      const chunks = [];
      for await (const chunk of request) chunks.push(chunk);
      const form = new URLSearchParams(Buffer.concat(chunks).toString()),
        code = form.get("code"),
        entry = codes.get(code);
      codes.delete(code);
      if (
        !entry ||
        form.get("grant_type") !== "authorization_code" ||
        form.get("client_id") !== "test-app" ||
        form.get("client_secret") !== "test-secret" ||
        form.get("redirect_uri") !== entry.redirect ||
        createHash("sha256")
          .update(form.get("code_verifier") ?? "")
          .digest("base64url") !== entry.challenge
      )
        return send(400, { error: "invalid_grant" });
      const now = Math.floor(Date.now() / 1000),
        { wrongSignature, ...claims } = entry.claims;
      const token = await new SignJWT({
        iss: issuer,
        aud: "test-app",
        sub: entry.subject,
        iat: now,
        exp: now + 300,
        nonce: entry.nonce,
        ...claims,
      })
        .setProtectedHeader({ alg: "RS256", kid: "test-key" })
        .sign(wrongSignature ? wrongKey.privateKey : key.privateKey);
      return send(200, {
        access_token: randomUUID(),
        token_type: "Bearer",
        expires_in: 300,
        id_token: token,
      });
    }
    send(404, { error: "not_found" });
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  issuer = `http://127.0.0.1:${server.address().port}/oidc`;
  const provider = createAuthingProvider(
    { issuer, clientId: "test-app", clientSecret: "test-secret" },
    () =>
      oidc.discovery(
        new URL(issuer),
        "test-app",
        { client_secret: "test-secret", id_token_signed_response_alg: "RS256" },
        oidc.ClientSecretPost("test-secret"),
        {
          timeout: 3,
          execute: [
            oidc.allowInsecureRequests,
            oidc.enableNonRepudiationChecks,
          ],
        },
      ),
  );
  return {
    issuer,
    provider,
    makeCode,
    get tokenCalls() {
      return tokenCalls;
    },
    async close() {
      server.closeAllConnections();
      await new Promise((resolve) => server.close(resolve));
    },
  };
}
