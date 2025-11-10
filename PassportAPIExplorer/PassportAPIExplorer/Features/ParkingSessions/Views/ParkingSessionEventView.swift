//
//  ParkingSessionEventView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

/// Main view for managing parking sessions (start, extend, stop).
/// Uses MVVM pattern: delegates business logic to ViewModels, focuses on UI presentation.
struct ParkingSessionEventView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var apiService: PassportAPIService
    var body: some View {
        ParkingSessionEventInnerView(apiService: apiService, modelContext: modelContext)
    }
}

private struct ParkingSessionEventInnerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var apiService: PassportAPIService
    @State private var listViewModel: ParkingSessionsListViewModel
    @State private var eventPublisher: ParkingSessionEventPublisherViewModel
    @State private var formViewModel: ParkingSessionEventFormViewModel
    @Query private var operators: [Operator]
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    
    @State private var selectedTab: EventTab = .start
    @State private var showingStartForm = false
    @State private var sessionDetailModal: ParkingSession?
    
    // Extend/Stop fields
    @State private var selectedSession: ParkingSession?
    
    enum EventTab: String, CaseIterable {
        case start = "Start"
        case extend = "Extend"
        case stop = "Stop"
    }
    
    init(apiService: PassportAPIService, modelContext: ModelContext) {
        let listVM = ParkingSessionsListViewModel(modelContext: modelContext)
        _listViewModel = State(initialValue: listVM)
        let eventPub = ParkingSessionEventPublisherViewModel(apiService: apiService, listViewModel: listVM)
        _eventPublisher = State(initialValue: eventPub)
        _formViewModel = State(initialValue: ParkingSessionEventFormViewModel(apiService: apiService, eventPublisher: eventPub))
    }
    
    var body: some View {
        Group {
            let completedSessions = listViewModel.sessions.filter { !$0.isActive }
            let hasDisplayableSessions = !listViewModel.activeSessions.isEmpty || !completedSessions.isEmpty
            
            if !hasDisplayableSessions {
                // No displayable sessions: Show landing page with pulsing car icon
                SessionLandingView(
                    onStartNewSession: { showingStartForm = true },
                    onRefresh: { await listViewModel.triggerSync() }
                )
            } else {
                // Has sessions (active or completed): Show sessions list
                SessionsListView(
                    activeSessions: listViewModel.activeSessions,
                    completedSessions: completedSessions,
                    operators: operators,
                    onRefresh: { await listViewModel.triggerSync() },
                    onStartNewSession: { showingStartForm = true },
                    onSessionSelected: { sessionDetailModal = $0 },
                    onExtendSession: { session in
                        selectedSession = session
                        selectedTab = .extend
                    },
                    onStopSession: { session in
                        selectedSession = session
                        selectedTab = .stop
                    },
                    onDeleteSession: { listViewModel.deleteSession($0) }
                )
                .sheet(item: $sessionDetailModal) { session in
                    NavigationStack {
                        SessionDetailView(
                            session: session,
                            operators: operators,
                            onDismiss: { sessionDetailModal = nil }
                        )
                    }
                }
                .sheet(isPresented: Binding(
                    get: { selectedSession != nil && selectedTab == .extend },
                    set: { if !$0 { selectedSession = nil } }
                )) {
                    if let session = selectedSession {
                        NavigationStack {
                            ExtendSessionFormView(session: session, formViewModel: formViewModel)
                                .navigationTitle("Extend Session")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                            selectedSession = nil
                                        }
                                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                    }
                                }
                                .overlay(alignment: .bottom) {
                                    VStack {
                                        Button(action: {
                                            Task {
                                                do {
                                                    try await formViewModel.submitExtendSession(session)
                                                    selectedSession = nil
                                                } catch {}
                                            }
                                        }) {
                                            Label("Extend Session", systemImage: "clock.arrow.circlepath")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(Color.adaptiveGlassBackground(colorScheme == .dark))
                                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
                                    )
                                }
                        }
                        .adaptiveGlassmorphismBackground()
                    }
                }
                .sheet(isPresented: Binding(
                    get: { selectedSession != nil && selectedTab == .stop },
                    set: { if !$0 { selectedSession = nil } }
                )) {
                    if let session = selectedSession {
                        NavigationStack {
                            StopSessionFormView(session: session, formViewModel: formViewModel)
                                .navigationTitle("Stop Session")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                            selectedSession = nil
                                        }
                                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                    }
                                }
                                .overlay(alignment: .bottom) {
                                    VStack {
                                        Button(action: {
                                            Task {
                                                do {
                                                    try await formViewModel.submitStopSession(session)
                                                    selectedSession = nil
                                                } catch {}
                                            }
                                        }) {
                                            Label("Stop Session", systemImage: "stop.circle.fill")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(Color.adaptiveGlassBackground(colorScheme == .dark))
                                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
                                    )
                                }
                        }
                        .adaptiveGlassmorphismBackground()
                    }
                }
            }
        }
        .adaptiveGlassmorphismBackground()
        .adaptiveGlassmorphismNavigation()
        .navigationTitle("Parking Sessions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingStartForm) {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    StartSessionFormView(formViewModel: formViewModel)
                    
                    // Floating button with frosted glass background
                    VStack(spacing: 0) {
                        VStack {
                            Button(action: {
                                Task {
                                    do {
                                        try await formViewModel.submitStartSession()
                                        showingStartForm = false
                                    } catch {}
                                }
                            }) {
                                Label("Start Parking Session", systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                            .disabled(!formViewModel.isStartFormValid)
                            .opacity(formViewModel.isStartFormValid ? 1.0 : 0.5)
                        }
                        .padding()
                        
                        Color.clear.frame(height: 0)
                    }
                    .background(
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.navyBlue.opacity(0.3) : Color.white.opacity(0.5))
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
                    )
                }
                .navigationTitle("Start New Session")
                .navigationBarTitleDisplayMode(.inline)
                .adaptiveGlassmorphismBackground()
                .adaptiveGlassmorphismNavigation()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingStartForm = false
                        }
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(eventPublisher.errorMessage != nil)) {
            Button("OK") { eventPublisher.clearMessages() }
        } message: {
            if let error = eventPublisher.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(eventPublisher.successMessage != nil)) {
            Button("OK") { eventPublisher.clearMessages() }
        } message: {
            if let success = eventPublisher.successMessage {
                Text(success)
            }
        }
        .overlay {
            if eventPublisher.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getZoneName(for session: ParkingSession) -> String {
        // If we have a stored zone name, use it
        if let zoneName = session.zoneName {
            return zoneName
        }
        
        // For external zone IDs, show the ID
        if session.computedZoneIdType == .external {
            return "External Zone: \(session.zoneId)"
        }
        
        // No zone name available
        return "Unknown Zone"
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ParkingSession.self, Operator.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let service = PreviewEnvironment.makePreviewService()
    
    return NavigationStack {
        ParkingSessionEventView()
    }
    .environmentObject(service)
    .modelContainer(container)
}
