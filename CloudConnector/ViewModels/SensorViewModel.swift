//
//  SensorViewModel.swift
//  CloudConnector
//
//  Created by Zayne Verlyn on 5/6/25.
//


import Foundation

@MainActor
class SensorViewModel: ObservableObject {
    @Published var readings: [SensorReading] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var isRunning = false

    func startAutoFetching(interval: UInt64 = 10) {
        guard !isRunning else {
            print("[Sensor Connector] Auto-fetching already running.")
            return
        }

        isRunning = true
        print("[Sensor Connector] Starting auto-fetching every \(interval) seconds.")

        Task {
            while isRunning {
                print("[Sensor Connector] Fetching new sensor reading...")
                await fetchReadings(showLoading: false)
                try? await Task.sleep(nanoseconds: interval * 1_000_000_000)
            }
        }
    }

    func stopAutoFetching() {
        isRunning = false
        print("[Sensor Connector] Stopped auto-fetching.")
    }

    func fetchReadings(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }

        do {
            let reading = try await API.fetchSensorReadings()
            self.readings = [reading]
            self.errorMessage = nil
            print("[Sensor Connector] Successfully fetched reading: \(reading)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("[Sensor Connector] Error fetching readings: \(error.localizedDescription)")
        }

        if showLoading {
            isLoading = false
        }
    }
}
