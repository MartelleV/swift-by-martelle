//
//  API.swift
//  CloudConnector
//
//  Created by Zayne Verlyn on 5/6/25.
//

import Foundation

struct API {
    static func fetchSensorReadings() async throws -> SensorReading {
        // API endpoint.
        guard let url = URL(string: "https://esp32-temp-6460420e7f72.herokuapp.com/data") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // !TODO: Replace (if API key is needed. If not, remove this line)
        // request.addValue("api_key", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Decode the JSON Object.
        let decoder = JSONDecoder()
        return try decoder.decode(SensorReading.self, from: data)
    }
}
