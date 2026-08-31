# Rule — Commit, Push, Secrets & Identity

**Load when:** staging, committing, or pushing files and directories.

- Never commit or push automatically — only commit and push when the user explicitly runs the command `@push`
- Never commit or push credentials or sensitive assets: API keys, secret keys, tokens, certificates, signing profiles, permission/entitlement files, datasets, ML model pipelines (training data, weights, `.mlmodel` sources), or `.gitignore`-matched identity files — WeatherKit uses entitlements, not keys
- Never commit developer identity: signing profiles, certificates, `*.mobileprovision`, `DEVELOPMENT_TEAM` (personal Apple ID / team ID), bundle identifiers (personal `com.<name>.*` IDs), or Xcode user data (`xcuserdata/`) — `.gitignore` already excludes them
