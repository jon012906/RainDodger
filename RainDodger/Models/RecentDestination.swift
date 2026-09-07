//
//  RecentDestination.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import Foundation
import SwiftData

@Model
final class RecentDestination {
    var id: UUID
    var name: String
    var street: String
    var latitude: Double
    var longitude: Double
    var categorySymbol: String
    var savedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        street: String,
        latitude: Double,
        longitude: Double,
        categorySymbol: String,
        savedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.street = street
        self.latitude = latitude
        self.longitude = longitude
        self.categorySymbol = categorySymbol
        self.savedAt = savedAt
    }

    convenience init(searchResult: SearchResult) {
        self.init(
            id: searchResult.id,
            name: searchResult.name,
            street: searchResult.street,
            latitude: searchResult.latitude,
            longitude: searchResult.longitude,
            categorySymbol: searchResult.categorySymbol
        )
    }

    var searchResult: SearchResult {
        SearchResult(
            id: id,
            name: name,
            street: street,
            latitude: latitude,
            longitude: longitude,
            categorySymbol: categorySymbol
        )
    }
}