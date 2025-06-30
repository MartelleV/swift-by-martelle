//
//  ContentView.swift
//  MQTTConnector
//
//  Created by Zayne Verlyn on 6/6/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SensorViewModel()
    @State private var showingCommandSheet = false
    @State private var customCommand = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Connection Status Card
                        ConnectionStatusView(
                            isConnected: viewModel.isConnected,
                            status: viewModel.connectionStatus
                        )
                        
                        if viewModel.isLoading {
                            LoadingView()
                        } else if let errorMessage = viewModel.errorMessage {
                            ErrorView(message: errorMessage) {
                                Task {
                                    await viewModel.fetchReadings()
                                }
                            }
                        } else if let reading = viewModel.readings.first {
                            SensorCardsView(reading: reading)

                            // Info Text
                            VStack(spacing: 8) {
                                Text("Connected via MQTT to receive real-time sensor data.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Data updates automatically. Tap ↻ to request fresh data.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            
                            // Send Command Button
                            Button(action: {
                                showingCommandSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Command")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.green)
                                )
                            }
                            .disabled(!viewModel.isConnected)
                        } else if viewModel.isConnected {
                            // Connected but no data yet
                            VStack(spacing: 16) {
                                Image(systemName: "sensor.tag.radiowaves.forward")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("Waiting for sensor data...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Button("Request Data") {
                                    Task {
                                        await viewModel.fetchReadings()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(40)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.regularMaterial)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("MQTT Sensors")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.fetchReadings(showLoading: true)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                viewModel.startAutoFetching()
            }
            .onDisappear {
                viewModel.stopAutoFetching()
            }
            .sheet(isPresented: $showingCommandSheet) {
                CommandSheetView(
                    command: $customCommand,
                    onSend: { command in
                        viewModel.sendCommand(command)
                        showingCommandSheet = false
                        customCommand = ""
                    }
                )
            }
        }
    }
}

struct ConnectionStatusView: View {
    let isConnected: Bool
    let status: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isConnected ? .green : .red)
                .frame(width: 12, height: 12)
            
            Text("MQTT: \(status)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isConnected ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .stroke(isConnected ? .green.opacity(0.3) : .red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CommandSheetView: View {
    @Binding var command: String
    let onSend: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    let predefinedCommands = [
        "REQUEST_DATA",
        "RESET",
        "CALIBRATE",
        "SET_INTERVAL_5",
        "SET_INTERVAL_10",
        "SET_INTERVAL_30"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Send Command to Sensor")
                    .font(.headline)
                    .padding(.top)
                
                // Predefined commands
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ], spacing: 12) {
                    ForEach(predefinedCommands, id: \.self) { cmd in
                        Button(cmd) {
                            onSend(cmd)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Custom command
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Command:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter custom command", text: $command)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Send Custom Command") {
                        if !command.isEmpty {
                            onSend(command)
                        }
                    }
                    .disabled(command.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Commands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Keep existing SensorCardsView, SensorCard, LoadingView, and ErrorView unchanged
struct SensorCardsView: View {
    let reading: SensorReading
    
    var body: some View {
        VStack(spacing: 16) {
            // Temperature Card
            SensorCard(
                icon: "thermometer.medium",
                title: "Temperature",
                value: String(format: "%.1f", reading.temperature),
                unit: "°C",
                color: .orange,
                backgroundColor: Color.orange.opacity(0.1)
            )

            // Humidity Card
            SensorCard(
                icon: "humidity",
                title: "Humidity",
                value: String(format: "%.1f", reading.humidity),
                unit: "%",
                color: .blue,
                backgroundColor: Color.blue.opacity(0.1)
            )
        }
    }
}

struct SensorCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)

            Text("Loading sensor data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text("Unable to load data")
                .font(.headline)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    ContentView()
}
