import Foundation
import CoreLocation

actor WeatherCache {
    struct CacheKey: Hashable {
        let geohash: String
        let forecastHour: Date

        init(coordinate: CLLocationCoordinate2D, arrivalTime: Date) {
            self.geohash = Self.geohash(for: coordinate, precision: 4)
            let hour = Calendar.current.dateInterval(of: .hour, for: arrivalTime)?.start ?? arrivalTime
            self.forecastHour = hour
        }

        private static func geohash(for coordinate: CLLocationCoordinate2D, precision: Int) -> String {
            let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"
            var latRange = (-90.0, 90.0)
            var lonRange = (-180.0, 180.0)
            var geohash = ""
            var bit = 0
            var ch = 0
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            while geohash.count < precision {
                if bit % 2 == 0 {
                    let mid = (lonRange.0 + lonRange.1) / 2
                    if lon >= mid {
                        ch |= 1 << (4 - bit % 5)
                        lonRange = (mid, lonRange.1)
                    } else {
                        lonRange = (lonRange.0, mid)
                    }
                } else {
                    let mid = (latRange.0 + latRange.1) / 2
                    if lat >= mid {
                        ch |= 1 << (4 - bit % 5)
                        latRange = (mid, latRange.1)
                    } else {
                        latRange = (latRange.0, mid)
                    }
                }
                bit += 1
                if bit % 5 == 0 {
                    geohash.append(base32[base32.index(base32.startIndex, offsetBy: ch)])
                    ch = 0
                }
            }
            return geohash
        }
    }

    struct CacheEntry {
        let forecast: WeatherForecastPoint
        let fetchedAt: Date
        let validUntil: Date

        var isExpired: Bool { Date() > validUntil }
    }

    private var storage: [CacheKey: CacheEntry] = [:]
    private var inFlight: [CacheKey: Task<WeatherForecastPoint, Error>] = [:]
    private let defaultTTL: TimeInterval = 900

    func forecast(
        at coordinate: CLLocationCoordinate2D,
        arrivalTime: Date,
        fetch: @escaping () async throws -> WeatherForecastPoint
    ) async throws -> WeatherForecastPoint {
        let key = CacheKey(coordinate: coordinate, arrivalTime: arrivalTime)

        if let entry = storage[key], !entry.isExpired {
            return entry.forecast
        }

        if let existing = inFlight[key] {
            return try await existing.value
        }

        let task = Task {
            let result = try await fetch()
            return result
        }
        inFlight[key] = task

        do {
            let result = try await task.value
            inFlight.removeValue(forKey: key)
            storage[key] = CacheEntry(
                forecast: result,
                fetchedAt: Date(),
                validUntil: Date().addingTimeInterval(defaultTTL)
            )
            return result
        } catch {
            inFlight.removeValue(forKey: key)
            throw error
        }
    }

    func clear() {
        storage.removeAll()
        inFlight.removeAll()
    }

    var count: Int { storage.count }
}
