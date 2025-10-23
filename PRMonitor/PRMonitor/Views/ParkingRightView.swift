//
//  ParkingRightView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ParkingRightView: View {
    
    let pr: ParkingRight
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(Color.green)
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
                    }
                    if let state = pr.vehicle_state {
                        Text(state)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let space = pr.space_number {
                        Text("Space \(space)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Time info
                HStack {
                    Text(formatTime(pr.start_time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("→")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(pr.end_time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // Reference ID
                    if let referenceId = pr.reference_id {
                        Text("Ref: \(referenceId)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
