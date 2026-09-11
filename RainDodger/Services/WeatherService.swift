//
//  WeatherService.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import Foundation
import CoreLocation
import WeatherKit

protocol WeatherService: AnyObject {
    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double
}

@MainActor
final class LiveWeatherService: WeatherService {
    private let service = WeatherKit.WeatherService()

    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double {
        print("☁️ [Weather] Requesting rain chance at lat=\(String(format: "%.4f", coordinate.latitude)), lon=\(String(format: "%.4f", coordinate.longitude)) arrival=\(arrival.formatted())")
        do {
            let weather = try await service.weather(
                for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            print("☁️ [Weather] Got weather. Condition: \(weather.currentWeather.condition.rawValue), temp: \(weather.currentWeather.temperature.formatted())")
            if let minuteForecast = weather.minuteForecast {
                print("☁️ [Weather] Minute forecast available (\(minuteForecast.forecast.count) entries)")
            } else {
                print("☁️ [Weather] No minute forecast")
            }
            print("☁️ [Weather] Hourly forecast: \(weather.hourlyForecast.forecast.count) entries")
            if let minuteWeather = minuteForecastEntry(in: weather, at: arrival) {
                print("☁️ [Weather] ✅ Using MINUTE forecast: \(minuteWeather.precipitationChance)")
                return minuteWeather.precipitationChance
            }
            if let hourWeather = hourForecastEntry(in: weather, at: arrival) {
                print("☁️ [Weather] ✅ Using HOUR forecast: \(hourWeather.precipitationChance)")
                return hourWeather.precipitationChance
            }
            let current = currentRainChance(weather)
            print("☁️ [Weather] ⚠️ Using CURRENT condition fallback: \(current) (condition=\(weather.currentWeather.condition.rawValue))")
            return current
        } catch {
            print("☁️ [Weather] ❌ ERROR: \(error)")
            throw error
        }
    }

    private func minuteForecastEntry(in weather: Weather, at arrival: Date) -> MinuteWeather? {
        weather.minuteForecast?.forecast.first {
            Calendar.current.isDate($0.date, equalTo: arrival, toGranularity: .minute)
        }
    }

    private func hourForecastEntry(in weather: Weather, at arrival: Date) -> HourWeather? {
        weather.hourlyForecast.forecast.first {
            Calendar.current.isDate($0.date, equalTo: arrival, toGranularity: .hour)
        }
    }

    private func currentRainChance(_ weather: Weather) -> Double {
        switch weather.currentWeather.condition {
        case .rain, .heavyRain, .drizzle, .freezingRain, .freezingDrizzle, .hail, .sleet,
             .snow, .heavySnow, .blizzard, .blowingSnow, .sunShowers, .flurries, .wintryMix,
             .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms,
             .hurricane, .tropicalStorm:
            return 1
        default:
            return 0
        }
    }
}

@MainActor
final class MockWeatherService: WeatherService {
    func rainChance(at coordinate: CLLocationCoordinate2D, on arrival: Date) async throws -> Double {
        try await Task.sleep(for: .milliseconds(80))
        let minute = Double(Calendar.current.component(.minute, from: arrival))
        let latitudeWave = (sin(coordinate.latitude * 3.0) + 1) / 2
        let longitudeWave = (cos(coordinate.longitude * 2.5) + 1) / 2
        let timeWave = (sin(minute * 0.35) + 1) / 2
        let raw = latitudeWave * 0.45 + longitudeWave * 0.35 + timeWave * 0.2
        return min(max(raw, 0), 1)
    }
}