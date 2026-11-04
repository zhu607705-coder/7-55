import * as oidc from "openid-client";
export interface AuthingSettings {
  issuer: string;
  clientId: string;
  clientSecret: string;
}
export interface LoginChecks {
  verifier: string;
  nonce: string;
  state: string;
}
/** Configuration loader is injectable for protocol tests; runtime never permits insecure discovery. */
export function createAuthingProvider(
  settings: AuthingSettings,
  loadConfiguration?: () => Promise<oidc.Configuration>,
) {
  let pending: Promise<oidc.Configuration> | undefined;
  const configuration = () => {
    pending ??= (
      loadConfiguration
        ? loadConfiguration()
        : oidc.discovery(
            new URL(settings.issuer),
            settings.clientId,
            {
              client_secret: settings.clientSecret,
              id_token_signed_response_alg: "RS256",
            },
            oidc.ClientSecretPost(settings.clientSecret),
            { timeout: 8, execute: [oidc.enableNonRepudiationChecks] },
          )
    ).catch((error) => {
      pending = undefined;
      throw error;
    });
    return pending;
  };
  return {
    issuer: settings.issuer,
    clientId: settings.clientId,
    async start(callback: string, checks: LoginChecks) {
      const config = await configuration();
      return oidc.buildAuthorizationUrl(config, {
        redirect_uri: callback,
        response_type: "code",
        response_mode: "query",
        scope: "openid",
        code_challenge: await oidc.calculatePKCECodeChallenge(checks.verifier),
        code_challenge_method: "S256",
        state: checks.state,
        nonce: checks.nonce,
        // Fresh user authentication also prevents a shared browser silently selecting the previous account.
        prompt: "login",
      }).href;
    },
    async complete(currentUrl: URL, checks: LoginChecks) {
      const tokens = await oidc.authorizationCodeGrant(
        await configuration(),
        currentUrl,
        {
          pkceCodeVerifier: checks.verifier,
          expectedNonce: checks.nonce,
          expectedState: checks.state,
          idTokenExpected: true,
        },
      );
      const claims = tokens.claims();
      if (!claims?.sub || claims.iss !== settings.issuer)
        throw new Error("Invalid identity.");
      // No provider tokens, email, phone, or provider profile are persisted by this platform.
      return { subject: claims.sub };
    },
    logout(returnTo: string) {
      const url = new URL("/login/profile/logout", settings.issuer);
      url.searchParams.set("app_id", settings.clientId);
      url.searchParams.set("redirect_uri", returnTo);
      return url.href;
    },
  };
}
export type AuthingProvider = ReturnType<typeof createAuthingProvider>;
