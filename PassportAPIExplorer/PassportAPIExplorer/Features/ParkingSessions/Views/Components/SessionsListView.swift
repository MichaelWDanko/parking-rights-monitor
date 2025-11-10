//
//  SessionsListView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// List view displaying active and completed parking sessions.
struct SessionsListView: View {
    let activeSessions: [ParkingSession]
    let completedSessions: [ParkingSession]
    let operators: [Operator]
    let onRefresh: () async -> Void
    let onStartNewSession: () -> Void
    let onSessionSelected: (ParkingSession) -> Void
    let onExtendSession: (ParkingSession) -> Void
    let onStopSession: (ParkingSession) -> Void
    let onDeleteSession: (ParkingSession) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sessions Section
                VStack(alignment: .leading, spacing: 12) {
                    if !activeSessions.isEmpty {
                        Text("Active Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .padding(.horizontal, 16)
                        
                        ForEach(activeSessions) { session in
                            SessionCardView(
                                session: session,
                                operators: operators,
                                onInfoTap: { onSessionSelected(session) },
                                onExtend: { onExtendSession(session) },
                                onStop: { onStopSession(session) },
                                onDelete: { onDeleteSession(session) }
                            )
                        }
                    }
                    
                    if !completedSessions.isEmpty {
                        Text("Completed Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .padding(.horizontal, 16)
                            .padding(.top, activeSessions.isEmpty ? 0 : 8)
                        
                        ForEach(completedSessions) { session in
                            SessionCardView(
                                session: session,
                                operators: operators,
                                onInfoTap: { onSessionSelected(session) },
                                onExtend: nil,
                                onStop: nil,
                                onDelete: { onDeleteSession(session) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100) // Padding for floating button
        }
        .refreshable {
            await onRefresh()
        }
        .safeAreaInset(edge: .bottom) {
            // Floating Start New Session button - always visible
            Button(action: onStartNewSession) {
                Label("Start New Session", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
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
    
    SessionsListView(
        activeSessions: [mockSession],
        completedSessions: [],
        operators: [],
        onRefresh: { 
            try? await Task.sleep(nanoseconds: 1_000_000_000) 
        },
        onStartNewSession: {},
        onSessionSelected: { _ in },
        onExtendSession: { _ in },
        onStopSession: { _ in },
        onDeleteSession: { _ in }
    )
    .adaptiveGlassmorphismBackground()
}

