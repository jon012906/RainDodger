import Foundation
import CoreLocation

enum RainRisk: CaseIterable, Comparable {
    case low
    case moderate
    case high
    case veryHigh

    static func < (lhs: RainRisk, rhs: RainRisk) -> Bool {
        lhs.order < rhs.order
    }

    static func == (lhs: RainRisk, rhs: RainRisk) -> Bool {
        lhs.order == rhs.order
    }

    private var order: Int {
        switch self {
        case .low: 0
        case .moderate: 1
        case .high: 2
        case .veryHigh: 3
        }
    }

    static func classify(chance: Double, amount: Double, condition: AppWeatherCondition) -> RainRisk {
        let chanceScore = min(chance, 1.0)
        let amountScore = min(amount / 10.0, 1.0)
        let conditionScore = condition.riskContribution
        let score = chanceScore * 0.5 + amountScore * 0.3 + conditionScore * 0.2
        switch score {
        case ..<0.25: return .low
        case ..<0.50: return .moderate
        case ..<0.75: return .high
        default: return .veryHigh
        }
    }

    var label: String {
        switch self {
        case .low: "Low"
        case .moderate: "Moderate"
        case .high: "High"
        case .veryHigh: "Very high"
        }
    }

    var icon: String {
        switch self {
        case .low: "sun.max.fill"
        case .moderate: "cloud.sun.fill"
        case .high: "cloud.rain.fill"
        case .veryHigh: "cloud.heavyrain.fill"
        }
    }
}

enum AppWeatherCondition: String {
    case clear, cloudy, rain, heavyRain, snow, thunderstorm, unknown

    var riskContribution: Double {
        switch self {
        case .clear: 0.0
        case .cloudy: 0.1
        case .rain: 0.6
        case .heavyRain: 0.9
        case .snow: 0.7
        case .thunderstorm: 1.0
        case .unknown: 0.3
        }
    }
}

struct RouteWeatherSegment: Identifiable {
    let id = UUID()
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let startDistance: CLLocationDistance
    let endDistance: CLLocationDistance
    let arrivalStartTime: Date
    let arrivalEndTime: Date
    let precipitationChance: Double
    let precipitationAmount: Double
    let rainRisk: RainRisk
    let condition: AppWeatherCondition
    let roadName: String

    var midpointDistance: CLLocationDistance {
        (startDistance + endDistance) / 2
    }

    var duration: TimeInterval {
        arrivalEndTime.timeIntervalSince(arrivalStartTime)
    }
}

struct WeatherTransition: Identifiable {
    let id = UUID()
    let segmentIndex: Int
    let fromRisk: RainRisk
    let toRisk: RainRisk
    let coordinate: CLLocationCoordinate2D
    let arrivalTime: Date
    let distanceFromStart: CLLocationDistance
}

struct WeatherForecastPoint {
    let coordinate: CLLocationCoordinate2D
    let distanceFromStart: CLLocationDistance
    let arrivalTime: Date
    let precipitationChance: Double
    let precipitationAmount: Double
    let condition: AppWeatherCondition
}

struct RouteStepWeather {
    let stepIndex: Int
    let instruction: String
    let distanceFromStart: CLLocationDistance
    let arrivalDate: Date
    let rainChance: Double
    let precipitationAmount: Double
    let condition: AppWeatherCondition
    let rainRisk: RainRisk
    let roadName: String

    var isTransition: Bool {
        rainRisk >= .high
    }
}
