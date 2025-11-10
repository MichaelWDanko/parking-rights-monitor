//
//  SessionCardView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Individual session card component displaying session information and actions.
struct SessionCardView: View {
    let session: ParkingSession
    let operators: [Operator]
    let onInfoTap: () -> Void
    let onExtend: (() -> Void)?
    let onStop: (() -> Void)?
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var isActiveNow: Bool {
        session.isActive && session.endTime > Date()
    }
    
    private var operatorName: String? {
        operators.first(where: { $0.id == session.operatorId })?.name
    }
    
    private var zoneName: String {
        if let zoneName = session.zoneName {
            return zoneName
        }
        if session.computedZoneIdType == .external {
            return "External Zone: \(session.zoneId)"
        }
        return "Unknown Zone"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Vehicle and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.vehiclePlate) (\(session.vehicleState))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    // Operator name
                    if let operatorName = operatorName {
                        Text(operatorName)
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    
                    // Zone name (without ID)
                    Text(zoneName)
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                Spacer()
                
                // Status and Info button
                HStack(spacing: 8) {
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                    }
                    .buttonStyle(.plain)
                    
                    Text(isActiveNow ? "Active" : "Stopped")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isActiveNow ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isActiveNow ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            // Time info
            HStack {
                Label(session.startTime.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "clock")
                Text("→")
                Label(session.endTime.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "clock.badge.checkmark")
            }
            .font(.caption)
            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            
            // Action buttons for active sessions
            if isActiveNow, let onExtend = onExtend, let onStop = onStop {
                HStack(spacing: 12) {
                    Button(action: onExtend) {
                        Label("Extend", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.adaptiveCyanAccent(colorScheme == .dark).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onStop) {
                        Label("Stop", systemImage: "stop.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .adaptiveGlassmorphismListRow()
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let mockSession = ParkingSession(
        operatorId: "test-op",
        zoneId: "test-zone",
        vehiclePlate: "ABC1234",
        vehicleState: "CA",
        endTime: Date().addingTimeInterval(3600)
    )
    
    let completedSession = ParkingSession(
        operatorId: "test-op",
        zoneId: "test-zone",
        vehiclePlate: "XYZ5678",
        vehicleState: "NY",
        endTime: Date().addingTimeInterval(-3600)
    )
    // Mark as inactive for preview
    completedSession.isActive = false
    
    return VStack(spacing: 16) {
        SessionCardView(
            session: mockSession,
            operators: [],
            onInfoTap: {},
            onExtend: {},
            onStop: {},
            onDelete: {}
        )
        
        SessionCardView(
            session: completedSession,
            operators: [],
            onInfoTap: {},
            onExtend: nil,
            onStop: nil,
            onDelete: {}
        )
    }
    .padding()
    .adaptiveGlassmorphismBackground()
}

