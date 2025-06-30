//
//  SensorReading.swift
//  MQTTConnector
//
//  Created by Zayne Verlyn on 5/6/25.
//

import Foundation

struct SensorReading: Codable, Identifiable {
    var id = UUID()          // Unique ID for SwiftUI list
    let temperature: Double
    let humidity: Double
    let timestamp: Date?     // Optional timestamp from MQTT message

    // Custom coding keys to exclude the id from JSON encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case temperature
        case humidity
        case timestamp
    }
    
    init(temperature: Double, humidity: Double, timestamp: Date? = nil) {
        self.temperature = temperature
        self.humidity = humidity
        self.timestamp = timestamp
    }
}
