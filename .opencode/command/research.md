---
description: Research a technical question (Apple APIs, agentic AI, ML) with a specialized researcher agent.
agent: researcher
subtask: true
---

The user has invoked `@research`. Delegate to the **Researcher** subagent with `$ARGUMENTS` as the question (e.g. `@research WeatherKit precipitation forecasts accuracy`, `@research agentic AI weather-scout architecture`). The researcher returns the full report: bottom line, findings with sources, tradeoffs, recommendation for scope, opinion/challenge, and a sources list. Do not modify the report; pass it through to the user as-is. Report only — do not implement anything.
