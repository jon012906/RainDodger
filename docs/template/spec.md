# Spec — <Feature Name>

_Usage: copy to `docs/specs/<feature>.md`, rename, and fill in._

## 1. Goal

What problem does this solve for the rider?

## 2. User Problem

What is painful/confusing/risky today?

## 3. Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| R1 | User can search destination | P0 | Uses MapKit |

## 4. Data Model

What models are needed?
Example: Trip, RoutePlan, RainSegment, SavedDestination.

Data relations can be visualized with an embedded **mermaid** diagram (rendered inline by GitHub, no separate source file):

```mermaid
erDiagram
  TRIP ||--o{ ROUTE_PLAN : has
  ROUTE_PLAN ||--o{ RAIN_SEGMENT : contains

## 5. Rules / Logic

How does the feature decide things?
Example: driest route scoring, rain thresholds, offline fallback.

## 6. Constraints

iOS version, privacy, WeatherKit limits, offline behavior, performance.

## 7. Acceptance Criteria

Clear checklist proving the feature is done.