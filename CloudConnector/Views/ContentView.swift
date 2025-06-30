//
//  ContentView.swift
//  CloudConnector
//
//  Created by Zayne Verlyn on 6/6/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SensorViewModel()
    
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

                            // ℹ️ Info Text
                            Text("Sensor data updates automatically every 10 seconds.\nTap the ↻ icon in the top-right corner to refresh manually.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Sensor Readings")
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
        }
    }
}

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
