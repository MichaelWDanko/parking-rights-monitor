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
        // Simple time formatting - you might want to use DateFormatter for more sophisticated formatting
        let components = timeString.components(separatedBy: " ")
        if components.count > 1 {
            let timePart = components[1].replacingOccurrences(of: "Z", with: "")
            let timeComponents = timePart.components(separatedBy: ":")
            if timeComponents.count >= 2 {
                return "\(timeComponents[0]):\(timeComponents[1])"
            }
        }
        return timeString
    }
}

#Preview {
    ParkingRightView(pr: right)
}
