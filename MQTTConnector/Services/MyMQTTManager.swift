//
//  MQTTManager.swift
//  MQTTConnector
//
//  Created by Zayne Verlyn on 5/6/25.
//

import Foundation
import CocoaMQTT // !WARNING: Must use CocoaMQTT 2.1.0 for compatibility, newer versions will break

class MyMQTTManager: ObservableObject {
    private var mqttClient: CocoaMQTT?
    
    // MQTT Configuration
    private let brokerHost = "sol1.swin.edu.vn"  // Public MQTT broker
    private let brokerPort: UInt16 = 1883
    private let clientID = "iOS_SensorApp_\(UUID().uuidString)"
    
    // MQTT Topics
    private let sensorDataTopic = "esp32/data/tuna"         // Topic to receive sensor data
    private let commandTopic = "esp32/commands/tuna"        // Topic to send commands
    private let statusTopic = "esp32/status/tuna"           // Topic for device status

    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"

    // Callbacks
    var onSensorDataReceived: ((SensorReading) -> Void)?
    var onConnectionStatusChanged: ((Bool, String) -> Void)?
    
    init() {
        setupMQTT()
    }

    private func setupMQTT() {
        mqttClient = CocoaMQTT(clientID: clientID, host: brokerHost, port: brokerPort)
        
        guard let client = mqttClient else { return }
        
        // Set connection properties
        client.username = ""
        client.password = ""
        client.keepAlive = 60
        client.cleanSession = true
        client.autoReconnect = true
        client.autoReconnectTimeInterval = 5

        // Set up delegates
        client.delegate = self

        // Enable logging (optional - can be disabled in production)
        client.logLevel = .warning
    }
    
    func connect() {
        guard let client = mqttClient else { return }
        
        updateConnectionStatus("Connecting...")
        
        if client.connect() {
            print("[MQTT] Attempting to connect to \(brokerHost):\(brokerPort)")
        } else {
            updateConnectionStatus("Connection failed")
            print("[MQTT] Connection attempt failed")
        }
    }
    
    func disconnect() {
        mqttClient?.disconnect()
        updateConnectionStatus("Disconnected")
    }
    
    func subscribe() {
        guard let client = mqttClient, client.connState == .connected else {
            print("[MQTT] Cannot subscribe - not connected")
            return
        }
        
        // Subscribe to sensor data topic
        client.subscribe(sensorDataTopic, qos: .qos1)
        client.subscribe(statusTopic, qos: .qos1)
        
        print("[MQTT] Subscribed to topics: \(sensorDataTopic), \(statusTopic)")
    }
    
    func sendCommand(_ command: String) {
        guard let client = mqttClient, client.connState == .connected else {
            print("[MQTT] Cannot send command - not connected")
            return
        }

        let message = CocoaMQTTMessage(topic: commandTopic, string: command, qos: .qos1)
        client.publish(message)
        print("[MQTT] Sent command: \(command)")
    }

    func sendSensorRequest() {
        sendCommand("REQUEST_DATA")
    }
    
    private func updateConnectionStatus(_ status: String) {
        DispatchQueue.main.async {
            self.connectionStatus = status
            self.isConnected = (status == "Connected")
            self.onConnectionStatusChanged?(self.isConnected, status)
        }
    }
    
    private func handleReceivedData(_ data: Data, topic: String) {
        if topic == sensorDataTopic {
            parseSensorData(data)
        } else if topic == statusTopic {
            handleStatusMessage(data)
        }
    }
    
    private func parseSensorData(_ data: Data) {
        do {
            // Try to parse as JSON first
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let temperature = json["temperature"] as? Double,
               let humidity = json["humidity"] as? Double {
                
                let reading = SensorReading(temperature: temperature, humidity: humidity, timestamp: Date())
                
                DispatchQueue.main.async {
                    self.onSensorDataReceived?(reading)
                }
                
                print("[MQTT] Parsed sensor data - Temp: \(temperature)°C, Humidity: \(humidity)%")
            }
            // Fallback: try to parse as comma-separated values
            else if let dataString = String(data: data, encoding: .utf8) {
                let components = dataString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ",")
                if components.count >= 2,
                   let temperature = Double(components[0].trimmingCharacters(in: .whitespaces)),
                   let humidity = Double(components[1].trimmingCharacters(in: .whitespaces)) {
                    
                    let reading = SensorReading(temperature: temperature, humidity: humidity, timestamp: Date())
                    
                    DispatchQueue.main.async {
                        self.onSensorDataReceived?(reading)
                    }
                    
                    print("[MQTT] Parsed CSV sensor data - Temp: \(temperature)°C, Humidity: \(humidity)%")
                }
            }
        } catch {
            print("[MQTT] Failed to parse sensor data: \(error)")
        }
    }
    
    private func handleStatusMessage(_ data: Data) {
        if let statusString = String(data: data, encoding: .utf8) {
            print("[MQTT] Device status: \(statusString)")
        }
    }
}

// MARK: - CocoaMQTTDelegate
extension MyMQTTManager: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            updateConnectionStatus("Connected")
            print("[MQTT] Connected successfully")
            
            // Auto-subscribe after successful connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.subscribe()
            }
        } else {
            updateConnectionStatus("Connection rejected: \(ack)")
            print("[MQTT] Connection rejected: \(ack)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("[MQTT] Published message to \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("[MQTT] Message \(id) published successfully")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("[MQTT] Received message on topic: \(message.topic)")

        let data = Data(message.payload)  // ✅ Convert [UInt8] to Data
        handleReceivedData(data, topic: message.topic)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("[MQTT] Subscribed to topics: \(success)")
        if !failed.isEmpty {
            print("[MQTT] Failed to subscribe to: \(failed)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("[MQTT] Unsubscribed from topics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Keep-alive ping
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Keep-alive pong response
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if let error = err {
            updateConnectionStatus("Disconnected: \(error.localizedDescription)")
            print("[MQTT] Disconnected with error: \(error)")
        } else {
            updateConnectionStatus("Disconnected")
            print("[MQTT] Disconnected")
        }
    }
}
