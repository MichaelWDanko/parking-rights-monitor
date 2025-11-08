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
            if listViewModel.activeSessions.isEmpty {
                // No active sessions: Show landing page
                landingPageView
            } else {
                // Has active sessions: Show sessions list with start button
                sessionsListView
            }
        }
        .adaptiveGlassmorphismBackground()
        .adaptiveGlassmorphismNavigation()
        .navigationTitle("Parking Sessions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingStartForm) {
            NavigationStack {
                startFormView
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
    
    // MARK: - Main Views
    
    @ViewBuilder
    private var landingPageView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Icon
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .symbolEffect(.pulse)
                    
                    VStack(spacing: 8) {
                        Text("No Active Parking Sessions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        Text("Start a new parking session to begin tracking")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Primary CTA Button
                Button(action: {
                    showingStartForm = true
                }) {
                    Label("Start New Session", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: UIScreen.main.bounds.height * 0.7)
        }
        .refreshable {
            await listViewModel.triggerSync()
        }
        .sheet(isPresented: $showingStartForm) {
            NavigationStack {
                startFormView
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
    }
    
    @ViewBuilder
    private var startFormView: some View {
        ZStack(alignment: .bottom) {
            Form {
                startSessionForm
                
                // Add padding at bottom for floating button
                Section {
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            
            // Floating button with frosted glass background
            VStack(spacing: 0) {
                // Button container
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
                
                // Extra space to cover bottom safe area
                Color.clear
                    .frame(height: 0)
            }
            .background(
                ZStack {
                    // Frosted glass background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // Subtle tint overlay
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.navyBlue.opacity(0.3) : Color.white.opacity(0.5))
                }
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
            )
        }
    }
    
    @ViewBuilder
    private var sessionsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Start New Session Card Button
                Button(action: {
                    showingStartForm = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start New Session")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text("Create a new parking session")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .adaptiveGlassmorphismListRow()
                
                // Sessions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Sessions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .padding(.horizontal, 16)
                    
                    ForEach(listViewModel.activeSessions) { session in
                        sessionCard(session)
                    }
                    
                    if !listViewModel.sessions.filter({ !$0.isActive }).isEmpty {
                        Text("Completed Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        ForEach(listViewModel.sessions.filter { !$0.isActive }) { session in
                            sessionCard(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            await listViewModel.triggerSync()
        }
        .sheet(item: $sessionDetailModal) { session in
            NavigationStack {
                sessionDetailView(session)
            }
        }
    }
    
    @ViewBuilder
    private func sessionCard(_ session: ParkingSession) -> some View {
        let isActiveNow = session.isActive && session.endTime > Date()
        VStack(alignment: .leading, spacing: 12) {
            // Header: Vehicle and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.vehiclePlate) (\(session.vehicleState))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    // Operator name
                    if let operatorName = operators.first(where: { $0.id == session.operatorId })?.name {
                        Text(operatorName)
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    
                    // Zone name (without ID)
                    Text(getZoneName(for: session))
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                Spacer()
                
                // Status and Info button
                HStack(spacing: 8) {
                    Button(action: {
                        sessionDetailModal = session
                    }) {
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
            if isActiveNow {
                HStack(spacing: 12) {
                    Button(action: {
                        selectedSession = session
                        selectedTab = .extend
                    }) {
                        Label("Extend", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.adaptiveCyanAccent(colorScheme == .dark).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        selectedSession = session
                        selectedTab = .stop
                    }) {
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
            Button(role: .destructive) {
                listViewModel.deleteSession(session)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedSession?.id == session.id && selectedTab == .extend },
            set: { if !$0 { selectedSession = nil } }
        )) {
            NavigationStack {
                extendSessionSheet(session)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedSession?.id == session.id && selectedTab == .stop },
            set: { if !$0 { selectedSession = nil } }
        )) {
            NavigationStack {
                stopSessionSheet(session)
            }
        }
    }
    
    // MARK: - Session Detail View
    
    @ViewBuilder
    private func sessionDetailView(_ session: ParkingSession) -> some View {
        Form {
            Section(header: Text("Vehicle Information").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                LabeledContent("License Plate", value: session.vehiclePlate)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("State", value: session.vehicleState)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Country", value: session.vehicleCountry)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                if let spaceNumber = session.spaceNumber {
                    LabeledContent("Space Number", value: spaceNumber)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: Text("Location").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                if let operatorName = operators.first(where: { $0.id == session.operatorId })?.name {
                    LabeledContent("Operator", value: operatorName)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                HStack {
                    Text("Zone ID Type")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(session.computedZoneIdType == .passport ? "Passport" : "External")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                
                LabeledContent("Zone", value: getZoneName(for: session))
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: Text("Session Times").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                LabeledContent("Start Time", value: session.startTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("End Time", value: session.endTime, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                LabeledContent("Created", value: session.dateCreated, format: .dateTime)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: Text("API Identifiers").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session ID")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    HStack {
                        Text(session.sessionId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = session.sessionId
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operator ID")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    HStack {
                        Text(session.operatorId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = session.operatorId
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zone ID")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    HStack {
                        Text(session.zoneId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = session.zoneId
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .listRowBackground(Color.glassBackground)
            
            Section(header: Text("Status").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                HStack {
                    Text("Session Status")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    Text(session.isActive ? "Active" : "Stopped")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(session.isActive ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(session.isActive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .listRowBackground(Color.glassBackground)
        }
        .scrollContentBackground(.hidden)
        .adaptiveGlassmorphismBackground()
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    sessionDetailModal = nil
                }
                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            }
        }
    }
    
    // MARK: - Extend/Stop Session Sheets
    
    @ViewBuilder
    private func extendSessionSheet(_ session: ParkingSession) -> some View {
        ZStack(alignment: .bottom) {
            Form {
                Section(header: Text("Session Details").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    LabeledContent("Vehicle", value: "\(session.vehiclePlate) (\(session.vehicleState))")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    LabeledContent("Zone", value: session.zoneId)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    LabeledContent("Current End", value: session.endTime, format: .dateTime)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("New End Time").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    DatePicker("End Time", selection: $formViewModel.newEndTime)
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("Extension Fees").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    feesFields()
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("Total Session Fees").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    totalFeesFields()
                }
                .listRowBackground(Color.glassBackground)
                
                // Padding for button
                Section {
                    Color.clear.frame(height: 80).listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            
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
        .adaptiveGlassmorphismBackground()
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
    }
    
    @ViewBuilder
    private func stopSessionSheet(_ session: ParkingSession) -> some View {
        ZStack(alignment: .bottom) {
            Form {
                Section(header: Text("Session Details").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    LabeledContent("Vehicle", value: "\(session.vehiclePlate) (\(session.vehicleState))")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    LabeledContent("Zone", value: session.zoneId)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    LabeledContent("Started", value: session.startTime, format: .dateTime)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("Actual End Time").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    DatePicker("End Time", selection: $formViewModel.newEndTime)
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("Stop Event Fees").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    Text("Can be negative for refunds")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    feesFields()
                }
                .listRowBackground(Color.glassBackground)
                
                Section(header: Text("Total Session Fees").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                    totalFeesFields()
                }
                .listRowBackground(Color.glassBackground)
                
                // Padding for button
                Section {
                    Color.clear.frame(height: 80).listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            
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
        .adaptiveGlassmorphismBackground()
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
    }
    
    @ViewBuilder
    private func feesFields() -> some View {
        HStack {
            Text("Parking")
            Spacer()
            TextField("0.00", text: $formViewModel.parkingFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Convenience")
            Spacer()
            TextField("0.00", text: $formViewModel.convenienceFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Tax")
            Spacer()
            TextField("0.00", text: $formViewModel.tax)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
    
    @ViewBuilder
    private func totalFeesFields() -> some View {
        HStack {
            Text("Parking")
            Spacer()
            TextField("0.00", text: $formViewModel.totalParkingFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Convenience")
            Spacer()
            TextField("0.00", text: $formViewModel.totalConvenienceFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Tax")
            Spacer()
            TextField("0.00", text: $formViewModel.totalTax)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
    
    // MARK: - Start Session Form
    
    @ViewBuilder
    private var startSessionForm: some View {
        Section {
            HStack {
                Text("Session ID Preview")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                Spacer()
                Button(action: { formViewModel.generateNewSessionId() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("New ID")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                .controlSize(.small)
            }
            
            HStack {
                Text(formViewModel.previewSessionId)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = formViewModel.previewSessionId
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .buttonStyle(.borderless)
            }
        }
        .listRowBackground(Color.glassBackground)
        
        Section(header: Text("Operator").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
            if operators.isEmpty {
                Text("No operators available. Add an operator first.")
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    .font(.caption)
            } else {
                Picker("Select Operator", selection: $formViewModel.selectedOperator) {
                    Text("Choose operator...").tag(nil as Operator?)
                    ForEach(operators) { op in
                        Text(op.name).tag(op as Operator?)
                    }
                }
                .onChange(of: formViewModel.selectedOperator) { _, newOperator in
                    formViewModel.handleOperatorChange(newOperator)
                }
                
                if let op = formViewModel.selectedOperator {
                    LabeledContent("Operator ID", value: op.id)
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
            }
        }
        .listRowBackground(Color.glassBackground)
        
        if formViewModel.selectedOperator != nil {
            Section(header: Text("Zone").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                Toggle("Use External Zone ID", isOn: $formViewModel.useExternalZoneId)
                    .onChange(of: formViewModel.useExternalZoneId) { _, isOn in
                        formViewModel.handleExternalZoneToggle(isOn)
                    }
                
                if formViewModel.useExternalZoneId {
                    TextField("External Zone ID", text: $formViewModel.externalZoneId, prompt: Text("Zone identifier"))
                        .autocapitalization(.none)
                } else {
                    if formViewModel.isLoadingZones {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading zones...")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                    } else if formViewModel.availableZones.isEmpty {
                        Text("No zones available for this operator")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .font(.caption)
                    } else {
                        Picker("Select Zone", selection: $formViewModel.selectedZone) {
                            Text("Choose zone...").tag(nil as Zone?)
                            ForEach(formViewModel.availableZones) { zone in
                                Text("\(zone.name) (\(zone.number))").tag(zone as Zone?)
                            }
                        }
                        
                        if let zone = formViewModel.selectedZone {
                            LabeledContent("Zone ID", value: zone.id)
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                    }
                }
            }
            .listRowBackground(Color.glassBackground)
        }
        
        Section {
            HStack {
                Text("Vehicle")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                Spacer()
                Button(action: { formViewModel.generateRandomVehicle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Random")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                .controlSize(.small)
            }
            
            TextField("License Plate", text: $formViewModel.vehiclePlate, prompt: Text("ABC1234"))
                .autocapitalization(.allCharacters)
            
            HStack {
                TextField("State Code", text: $formViewModel.vehicleState, prompt: Text("CA"))
                    .autocapitalization(.allCharacters)
                
                TextField("Country Code", text: $formViewModel.vehicleCountry, prompt: Text("US"))
                    .autocapitalization(.allCharacters)
            }
            
            TextField("Space Number (Optional)", text: $formViewModel.spaceNumber, prompt: Text("1-50"))
        }
        .listRowBackground(Color.glassBackground)
        
        Section(header: Text("Session Times").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
            DatePicker("Start Time", selection: $formViewModel.startTime)
            
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("End Time", selection: $formViewModel.endTime)
                
                HStack(spacing: 8) {
                    Text("Quick Duration:")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    Button("30m") {
                        formViewModel.setQuickDuration(1800)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("1h") {
                        formViewModel.setQuickDuration(3600)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("2h") {
                        formViewModel.setQuickDuration(7200)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("4h") {
                        formViewModel.setQuickDuration(14400)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("8h") {
                        formViewModel.setQuickDuration(28800)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                }
            }
        }
        .listRowBackground(Color.glassBackground)
        
        Section {
            HStack {
                Text("Event Fees")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                Spacer()
                Button(action: { formViewModel.generateRandomFees() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Random")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                .controlSize(.small)
            }
            
            HStack {
                Text("Parking Fee")
                Spacer()
                TextField("Amount", text: $formViewModel.parkingFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Convenience Fee")
                Spacer()
                TextField("Amount", text: $formViewModel.convenienceFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                TextField("Amount", text: $formViewModel.tax)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Currency Code")
                Spacer()
                TextField("USD", text: $formViewModel.currencyCode)
                    .autocapitalization(.allCharacters)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .listRowBackground(Color.glassBackground)
        
        Section(header: Text("Optional").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
            TextField("Account ID", text: $formViewModel.accountId, prompt: Text("User account UUID"))
                .autocapitalization(.none)
            
            TextField("Rate Name", text: $formViewModel.rateName, prompt: Text("e.g., $1.25/hour"))
        }
        .listRowBackground(Color.glassBackground)
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
