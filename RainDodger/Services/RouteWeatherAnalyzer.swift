import Foundation
import CoreLocation

struct RouteWeatherAnalyzer {
    static let transitionThreshold: Double = 0.20
    static let aggregationChanceTolerance: Double = 0.15

    struct AnalyzedRoute {
        let weatherSegments: [RouteWeatherSegment]
        let transitions: [WeatherTransition]
        let stepWeathers: [RouteStepWeather]
        let overallRisk: RainRisk
        let totalWetDistance: CLLocationDistance
        let totalDistance: CLLocationDistance
    }

    static func analyze(
        forecastPoints: [WeatherForecastPoint],
        steps: [RouteStep],
        totalDistance: CLLocationDistance,
        departure: Date?
    ) -> AnalyzedRoute {
        let segments = buildSegments(from: forecastPoints, steps: steps, totalDistance: totalDistance)
        let transitions = detectTransitions(in: segments)
        let stepWeathers = mapWeatherToSteps(steps: steps, forecastPoints: forecastPoints, totalDistance: totalDistance, departure: departure)
        let overallRisk = computeOverallRisk(segments: segments)
        let wetDistance = computeWetDistance(segments: segments, totalDistance: totalDistance)

        return AnalyzedRoute(
            weatherSegments: segments,
            transitions: transitions,
            stepWeathers: stepWeathers,
            overallRisk: overallRisk,
            totalWetDistance: wetDistance,
            totalDistance: totalDistance
        )
    }

    private static func buildSegments(
        from points: [WeatherForecastPoint],
        steps: [RouteStep],
        totalDistance: CLLocationDistance
    ) -> [RouteWeatherSegment] {
        guard points.count >= 2 else { return [] }
        var segments: [RouteWeatherSegment] = []
        for i in 0..<(points.count - 1) {
            let current = points[i]
            let next = points[i + 1]
            let roadName = findRoadName(for: current.distanceFromStart, in: steps)
            let risk = RainRisk.classify(
                chance: current.precipitationChance,
                amount: current.precipitationAmount,
                condition: current.condition
            )
            segments.append(RouteWeatherSegment(
                startCoordinate: current.coordinate,
                endCoordinate: next.coordinate,
                startDistance: current.distanceFromStart,
                endDistance: next.distanceFromStart,
                arrivalStartTime: current.arrivalTime,
                arrivalEndTime: next.arrivalTime,
                precipitationChance: current.precipitationChance,
                precipitationAmount: current.precipitationAmount,
                rainRisk: risk,
                condition: current.condition,
                roadName: roadName
            ))
        }
        if let last = points.last {
            let roadName = findRoadName(for: last.distanceFromStart, in: steps)
            let risk = RainRisk.classify(
                chance: last.precipitationChance,
                amount: last.precipitationAmount,
                condition: last.condition
            )
            segments.append(RouteWeatherSegment(
                startCoordinate: last.coordinate,
                endCoordinate: last.coordinate,
                startDistance: last.distanceFromStart,
                endDistance: totalDistance,
                arrivalStartTime: last.arrivalTime,
                arrivalEndTime: last.arrivalTime.addingTimeInterval(60),
                precipitationChance: last.precipitationChance,
                precipitationAmount: last.precipitationAmount,
                rainRisk: risk,
                condition: last.condition,
                roadName: roadName
            ))
        }
        return segments
    }

    private static func detectTransitions(in segments: [RouteWeatherSegment]) -> [WeatherTransition] {
        guard segments.count >= 2 else { return [] }
        var transitions: [WeatherTransition] = []
        for i in 0..<(segments.count - 1) {
            let current = segments[i]
            let next = segments[i + 1]
            let chanceDiff = abs(next.precipitationChance - current.precipitationChance)
            let riskChanged = current.rainRisk != next.rainRisk
            if chanceDiff >= transitionThreshold || riskChanged {
                transitions.append(WeatherTransition(
                    segmentIndex: i + 1,
                    fromRisk: current.rainRisk,
                    toRisk: next.rainRisk,
                    coordinate: next.startCoordinate,
                    arrivalTime: next.arrivalStartTime,
                    distanceFromStart: next.startDistance
                ))
            }
        }
        return transitions
    }

    static func mapWeatherToSteps(
        steps: [RouteStep],
        forecastPoints: [WeatherForecastPoint],
        totalDistance: CLLocationDistance,
        departure: Date?
    ) -> [RouteStepWeather] {
        guard !forecastPoints.isEmpty else { return [] }
        let departureValue = departure ?? Date()
        return steps.enumerated().map { offset, step in
            let endDistance = offset + 1 < steps.count
                ? steps[offset + 1].distanceFromStart
                : max(totalDistance, step.distanceFromStart)
            let midpoint = (step.distanceFromStart + endDistance) / 2
            let nearest = nearestForecast(to: midpoint, in: forecastPoints)
            let fraction = totalDistance > 0 ? step.distanceFromStart / totalDistance : 0
            let totalStepDistance = steps.last?.distanceFromStart ?? totalDistance
            let arrivalDate = departureValue.addingTimeInterval(fraction * totalStepDistance)
            let risk = RainRisk.classify(
                chance: nearest?.precipitationChance ?? 0,
                amount: nearest?.precipitationAmount ?? 0,
                condition: nearest?.condition ?? .unknown
            )
            return RouteStepWeather(
                stepIndex: offset,
                instruction: step.instruction,
                distanceFromStart: step.distanceFromStart,
                arrivalDate: arrivalDate,
                rainChance: nearest?.precipitationChance ?? 0,
                precipitationAmount: nearest?.precipitationAmount ?? 0,
                condition: nearest?.condition ?? .unknown,
                rainRisk: risk,
                roadName: extractRoadName(from: step.instruction)
            )
        }
    }

    private static func nearestForecast(
        to distance: CLLocationDistance,
        in points: [WeatherForecastPoint]
    ) -> WeatherForecastPoint? {
        points.min { abs($0.distanceFromStart - distance) < abs($1.distanceFromStart - distance) }
    }

    private static func findRoadName(for distance: CLLocationDistance, in steps: [RouteStep]) -> String {
        for step in steps {
            let end = step.distanceFromStart + step.distance
            if distance >= step.distanceFromStart && distance < end {
                return extractRoadName(from: step.instruction)
            }
        }
        return steps.last.map { extractRoadName(from: $0.instruction) } ?? ""
    }

    static func extractRoadName(from instruction: String) -> String {
        let patterns = [
            #"on (.+?)(?:\s*,|\s*for|\s*$)"#,
            #"onto (.+?)(?:\s*,|\s*for|\s*$)"#,
            #"toward (.+?)(?:\s*,|\s*for|\s*$)"#,
            #"Continue on (.+?)(?:\s*,|\s*$)"#
        ]
        for pattern in patterns {
            if let range = instruction.range(of: pattern, options: .regularExpression) {
                let match = String(instruction[range])
                for prefix in ["on ", "onto ", "toward ", "Continue on "] {
                    if let roadRange = match.range(of: prefix) {
                        let road = String(match[roadRange.upperBound...])
                        if !road.isEmpty { return road.trimmingCharacters(in: .whitespaces) }
                    }
                }
            }
        }
        let words = instruction.split(separator: " ")
        if words.count >= 3 {
            return words.suffix(from: 2).prefix(3).joined(separator: " ")
        }
        return instruction
    }

    private static func computeOverallRisk(segments: [RouteWeatherSegment]) -> RainRisk {
        guard !segments.isEmpty else { return .low }
        let maxRisk = segments.map(\.rainRisk).max() ?? .low
        let avgChance = segments.map(\.precipitationChance).reduce(0, +) / Double(segments.count)
        if maxRisk >= .veryHigh { return .veryHigh }
        if maxRisk >= .high || avgChance >= 0.5 { return .high }
        if maxRisk >= .moderate || avgChance >= 0.25 { return .moderate }
        return .low
    }

    private static func computeWetDistance(segments: [RouteWeatherSegment], totalDistance: CLLocationDistance) -> CLLocationDistance {
        segments.filter { $0.rainRisk >= .high }.reduce(0) { $0 + ($1.endDistance - $1.startDistance) }
    }
}
