import Foundation
import CoreLocation

struct AdaptiveRouteSampler {
    let baseSamplingDistance: CLLocationDistance
    let maxSamples: Int
    let transitionThreshold: Double
    let maxDensificationPasses: Int

    init(
        baseSamplingDistance: CLLocationDistance = 10_000,
        maxSamples: Int = 60,
        transitionThreshold: Double = 0.20,
        maxDensificationPasses: Int = 2
    ) {
        self.baseSamplingDistance = baseSamplingDistance
        self.maxSamples = maxSamples
        self.transitionThreshold = transitionThreshold
        self.maxDensificationPasses = maxDensificationPasses
    }

    struct SamplePoint {
        let coordinate: CLLocationCoordinate2D
        let distanceFromStart: CLLocationDistance
        let index: Int
    }

    func initialSamples(from points: [CLLocationCoordinate2D]) -> [SamplePoint] {
        guard let first = points.first else { return [] }
        var samples = [SamplePoint(coordinate: first, distanceFromStart: 0, index: 0)]
        var accumulated: CLLocationDistance = 0
        var nextThreshold = baseSamplingDistance
        var previous = first
        for point in points.dropFirst() {
            accumulated += Self.distance(from: previous, to: point)
            if accumulated >= nextThreshold, samples.count < maxSamples {
                samples.append(SamplePoint(coordinate: point, distanceFromStart: accumulated, index: samples.count))
                nextThreshold += baseSamplingDistance
            }
            previous = point
        }
        if let last = points.last, let lastSample = samples.last, lastSample.distanceFromStart < accumulated {
            samples.append(SamplePoint(coordinate: last, distanceFromStart: accumulated, index: samples.count))
        }
        return samples
    }

    func densify(
        samples: [SamplePoint],
        forecasts: [WeatherForecastPoint],
        along points: [CLLocationCoordinate2D]
    ) -> [SamplePoint] {
        guard samples.count >= 2, forecasts.count >= 2 else { return samples }
        var currentSamples = samples
        var currentForecasts = forecasts
        for _ in 0..<maxDensificationPasses {
            let newPoints = findTransitionMidpoints(samples: currentSamples, forecasts: currentForecasts)
            guard !newPoints.isEmpty, currentSamples.count + newPoints.count <= maxSamples else { break }
            let merged = (currentSamples + newPoints).sorted { $0.distanceFromStart < $1.distanceFromStart }
            let reindexed = merged.enumerated().map { SamplePoint(coordinate: $0.element.coordinate, distanceFromStart: $0.element.distanceFromStart, index: $0.offset) }
            currentSamples = reindexed
            currentForecasts = reindexed.map { pt in
                WeatherForecastPoint(
                    coordinate: pt.coordinate,
                    distanceFromStart: pt.distanceFromStart,
                    arrivalTime: Date(),
                    precipitationChance: 0,
                    precipitationAmount: 0,
                    condition: .unknown
                )
            }
        }
        return currentSamples
    }

    private func findTransitionMidpoints(
        samples: [SamplePoint],
        forecasts: [WeatherForecastPoint]
    ) -> [SamplePoint] {
        var midpoints: [SamplePoint] = []
        for i in 0..<(forecasts.count - 1) {
            let current = forecasts[i]
            let next = forecasts[i + 1]
            let diff = abs(next.precipitationChance - current.precipitationChance)
            if diff >= transitionThreshold {
                let midDistance = (current.distanceFromStart + next.distanceFromStart) / 2
                let midCoord = interpolateCoordinate(
                    from: samples[i].coordinate,
                    to: samples[i + 1].coordinate,
                    fraction: 0.5
                )
                midpoints.append(SamplePoint(
                    coordinate: midCoord,
                    distanceFromStart: midDistance,
                    index: -1
                ))
            }
        }
        return midpoints
    }

    private func interpolateCoordinate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )
    }

    static func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}
