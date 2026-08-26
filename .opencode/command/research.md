---
description: Research a technical question (Apple APIs, frameworks, ML) and report findings with sources, tradeoffs, and a recommendation.
---

The user has invoked `@research`. Research the technical question given in `$ARGUMENTS` (e.g. `@research WeatherKit precipitation forecasts accuracy`, `@research Core ML rain prediction on-device`). Report only — do not implement anything.

1. Identify the exact question to answer from `$ARGUMENTS`. If it is ambiguous, split into the sub-questions most relevant to Rain Dodger.
2. Research using web search and fetching official docs first: Apple developer docs (`developer.apple.com`), then credible second-party sources (WWDC session pages, Apple blogs, reputable technical blogs/forums). Open the actual pages when a summary is not enough.
3. Evaluate findings strictly against the Rain Dodger tech stack (`AGENTS.md`):
   - iOS 26.x, iPhone 13+; modern SwiftUI/`@Observable`/SwiftData; MapKit, WeatherKit, CoreLocation, Core ML
   - Services behind protocols, async/await; no third-party SDKs unless the findings justify it
   - Motorcyclist UX: glanceable, gloves-friendly, high contrast
4. Report back concisely as:
   - **Bottom line:** the direct answer to the question (1–3 sentences)
   - **Findings:** key facts with source links; flag anything version-specific (iOS 26 / Xcode version matters)
   - **Tradeoffs / risks:** accuracy, battery, latency, API limits, entitlements, availability on device, footguns
   - **Recommendation:** what to do next in Rain Dodger (e.g. "use WeatherKit hourly precipitation for the rain overlay; defer Core ML until X"), with confidence level (high/medium/low)
   - If the research is big, break it into a report with the sub-questions answered in order
5. Do NOT write code, change files, or commit. If the user wants implementation after a decision, suggest `@implement` instead.
6. If a finding contradicts `AGENTS.md` or an existing decision, say so explicitly and let the user decide (`Working agreement: final decision is the user's`).
