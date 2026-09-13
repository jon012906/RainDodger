import Foundation
import WeatherKit

struct ForecastInterpolator {
    static func interpolatedForecast(
        for arrivalTime: Date,
        from weather: Weather
    ) -> (chance: Double, amount: Double, condition: AppWeatherCondition) {
        if let minute = minuteForecast(for: arrivalTime, in: weather) {
            return (minute.precipitationChance, minute.precipitationIntensity.value, mapCondition(weather.currentWeather.condition))
        }
        let hourly = weather.hourlyForecast.forecast
        guard hourly.count >= 2 else {
            return (currentRainChance(weather), weather.currentWeather.precipitationIntensity.value, mapCondition(weather.currentWeather.condition))
        }
        let sorted = hourly.sorted { $0.date < $1.date }
        guard let later = sorted.first(where: { $0.date >= arrivalTime }),
              let earlier = sorted.last(where: { $0.date <= arrivalTime }) else {
            if let closest = sorted.min(by: { abs($0.date.timeIntervalSince(arrivalTime)) < abs($1.date.timeIntervalSince(arrivalTime)) }) {
                return (closest.precipitationChance, closest.precipitationAmount.value, mapCondition(closest.condition))
            }
            return (currentRainChance(weather), weather.currentWeather.precipitationIntensity.value, mapCondition(weather.currentWeather.condition))
        }
        guard earlier.date != later.date else {
            return (earlier.precipitationChance, earlier.precipitationAmount.value, mapCondition(earlier.condition))
        }
        let interval = later.date.timeIntervalSince(earlier.date)
        let elapsed = arrivalTime.timeIntervalSince(earlier.date)
        let alpha = interval > 0 ? elapsed / interval : 0
        let chance = earlier.precipitationChance + alpha * (later.precipitationChance - earlier.precipitationChance)
        let amount = earlier.precipitationAmount.value + alpha * (later.precipitationAmount.value - earlier.precipitationAmount.value)
        let condition = alpha > 0.5 ? mapCondition(later.condition) : mapCondition(earlier.condition)
        return (chance, amount, condition)
    }

    private static func minuteForecast(for arrivalTime: Date, in weather: Weather) -> MinuteWeather? {
        weather.minuteForecast?.forecast.first {
            Calendar.current.isDate($0.date, equalTo: arrivalTime, toGranularity: .minute)
        }
    }

    private static func currentRainChance(_ weather: Weather) -> Double {
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

    private static func mapCondition(_ wkCondition: WeatherKit.WeatherCondition) -> AppWeatherCondition {
        switch wkCondition {
        case .rain, .drizzle, .freezingRain, .freezingDrizzle, .sunShowers:
            return .rain
        case .heavyRain, .hail, .sleet, .thunderstorms, .isolatedThunderstorms,
             .scatteredThunderstorms, .strongStorms, .hurricane, .tropicalStorm:
            return .heavyRain
        case .snow, .heavySnow, .blizzard, .blowingSnow, .flurries, .wintryMix:
            return .snow
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy
        case .clear, .mostlyClear, .hot, .breezy, .windy, .foggy, .haze:
            return .clear
        @unknown default:
            return .unknown
        }
    }
}
