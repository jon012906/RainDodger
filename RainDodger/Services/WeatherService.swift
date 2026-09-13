import Foundation
import CoreLocation
import WeatherKit

protocol WeatherService: AnyObject {
    func weatherForecast(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> WeatherForecastPoint
    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double
}

extension WeatherService {
    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double {
        let forecast = try await weatherForecast(at: coordinate, on: arrival)
        return forecast.precipitationChance
    }
}

@MainActor
final class LiveWeatherService: WeatherService {
    private let service = WeatherKit.WeatherService()

    func weatherForecast(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> WeatherForecastPoint {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try await service.weather(for: location)
        let interpolated = ForecastInterpolator.interpolatedForecast(for: arrival, from: weather)
        return WeatherForecastPoint(
            coordinate: coordinate,
            distanceFromStart: 0,
            arrivalTime: arrival,
            precipitationChance: interpolated.chance,
            precipitationAmount: interpolated.amount,
            condition: interpolated.condition
        )
    }

    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double {
        let forecast = try await weatherForecast(at: coordinate, on: arrival)
        return forecast.precipitationChance
    }
}

@MainActor
final class MockWeatherService: WeatherService {
    func weatherForecast(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> WeatherForecastPoint {
        try await Task.sleep(for: .milliseconds(80))
        let wave = (sin(coordinate.latitude * 5.0) + cos(coordinate.longitude * 3.0) + 2.0) / 4.0
        let amount = wave * 8.0
        let condition: AppWeatherCondition = wave > 0.6 ? .rain : wave > 0.3 ? .cloudy : .clear
        return WeatherForecastPoint(
            coordinate: coordinate,
            distanceFromStart: 0,
            arrivalTime: arrival,
            precipitationChance: wave,
            precipitationAmount: amount,
            condition: condition
        )
    }

    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double {
        let forecast = try await weatherForecast(at: coordinate, on: arrival)
        return forecast.precipitationChance
    }
}
