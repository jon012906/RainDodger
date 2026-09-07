//
//  SearchResult.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import Foundation
import CoreLocation

struct SearchResult: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let street: String
    let latitude: Double
    let longitude: Double
    let categorySymbol: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}