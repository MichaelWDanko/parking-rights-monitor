//
//  ParkingRightView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ParkingRightView: View {
    
    let pr: ParkingRight
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .onAppear {
                    print("🚗 ParkingRightView: Displaying \(pr.vehicle_plate ?? "N/A")")
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // Vehicle info
                HStack {
                    if let plate = pr.vehicle_plate {
                        Text(plate)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                    if let state = pr.vehicle_state {
                        Text(state)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    Spacer()
                    if let space = pr.space_number {
                        Text("Space \(space)")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
                
                // Time info
                HStack {
                    Text(formatTime(pr.start_time))
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    Text("→")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    Text(formatTime(pr.end_time))
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    Spacer()
                    
                    // Reference ID
                    if let referenceId = pr.reference_id {
                        Text("Ref: \(referenceId)")
                            .font(.caption2)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.glassBackground)
                            .cornerRadius(4)
                    }
                }
                HStack {
                    Text(pr.timeRemainingDescription)
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .adaptiveGlassmorphismListRow()
    }
    
    // Computed property to determine status color based on expiration time
    private var statusColor: Color {
        let now = Date()
        let endTime = parseEndTime(pr.end_time)
        
        // If we can't parse the end time, default to green
        guard let endDate = endTime else {
            return .green
        }
        
        // Calculate time difference in minutes
        let timeDifference = endDate.timeIntervalSince(now) / 60
        
        // If expires within 10 minutes, show orange; otherwise green
        return timeDifference <= 10 ? .orange : .green
    }
    
    private func parseEndTime(_ timeString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first
        if let date = formatter.date(from: timeString) {
            return date
        }
        
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timeString)
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first
        if let date = formatter.date(from: timeString) {
            return formatLocalTime(date)
        }
        
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: timeString) {
            return formatLocalTime(date)
        }
        
        // If all else fails, return the original string
        return timeString
    }
    
    private func formatLocalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

#Preview {
    ParkingRightView(pr: right)
}
