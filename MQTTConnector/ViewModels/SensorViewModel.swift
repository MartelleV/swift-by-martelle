//
//  SensorViewModel.swift
//  MQTTConnector
//
//  Created by Zayne Verlyn on 5/6/25.
//

import Foundation

@MainActor
class SensorViewModel: ObservableObject {
    @Published var readings: [SensorReading] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var connectionStatus: String = "Disconnected"
    @Published var isConnected: Bool = false
    
    private let mqttManager = MyMQTTManager()
    private var autoRequestTimer: Timer?
    
    init() {
        setupMQTTCallbacks()
    }
    
    private func setupMQTTCallbacks() {
        mqttManager.onSensorDataReceived = { [weak self] reading in
            guard let self = self else { return }
            
            self.readings = [reading]  // Keep only the latest reading
            self.errorMessage = nil
            self.isLoading = false
            
            print("[Sensor Connector] Received new reading via MQTT: \(reading)")
        }
        
        mqttManager.onConnectionStatusChanged = { [weak self] connected, status in
            guard let self = self else { return }
            
            self.isConnected = connected
            self.connectionStatus = status
            
            if !connected {
                self.errorMessage = "MQTT connection lost"
            } else {
                self.errorMessage = nil
                // Request initial data when connected
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    Task { @MainActor in  // ✅ Swift 6 fix
                        self.requestSensorData()
                    }
                }
            }
        }
    }
    
    func startAutoFetching(interval: TimeInterval = 10.0) {
        print("[Sensor Connector] Starting MQTT connection and auto-requests every \(interval) seconds.")
        
        // Connect to MQTT broker
        mqttManager.connect()
        
        // Start auto-requesting data
        autoRequestTimer?.invalidate()
        autoRequestTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in  // ✅ Swift 6 fix
                self.requestSensorData()
            }
        }
    }
    
    func stopAutoFetching() {
        autoRequestTimer?.invalidate()
        autoRequestTimer = nil
        mqttManager.disconnect()
        print("[Sensor Connector] Stopped auto-fetching and disconnected from MQTT.")
    }
    
    func fetchReadings(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        
        if !isConnected {
            mqttManager.connect()
            // Wait a bit for connection before requesting data
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        requestSensorData()
        
        // If still loading after 5 seconds, show timeout error
        if showLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.isLoading {
                    self.isLoading = false
                    if self.readings.isEmpty {
                        self.errorMessage = "Request timeout - no data received"
                    }
                }
            }
        }
    }
    
    private func requestSensorData() {
        guard isConnected else {
            print("[Sensor Connector] Cannot request data - not connected to MQTT")
            return
        }
        
        mqttManager.sendSensorRequest()
        print("[Sensor Connector] Requested sensor data via MQTT")
    }
    
    // Method to send custom commands to the sensor device
    func sendCommand(_ command: String) {
        guard isConnected else {
            errorMessage = "Cannot send command - not connected to MQTT"
            return
        }
        
        mqttManager.sendCommand(command)
        print("[Sensor Connector] Sent custom command: \(command)")
    }

    deinit {
        // Direct cleanup without capturing self in an escaping context
        autoRequestTimer?.invalidate()
        mqttManager.disconnect()
        print("[Sensor Connector] Stopped auto-fetching and disconnected from MQTT.")
    }
}
