//
//  ParkingSessionEventView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI
import SwiftData

struct ParkingSessionEventView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var apiService: PassportAPIService
    @StateObject private var viewModel: ParkingSessionEventViewModel
    @Query private var operators: [Operator]
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    
    @State private var selectedTab: EventTab = .start
    @State private var previewSessionId: String = ParkingSession.generateSessionId()
    @State private var showingStartForm = false
    @State private var sessionDetailModal: ParkingSession?
    
    // Start session fields
    @State private var selectedOperator: Operator?
    @State private var useExternalZoneId = false
    @State private var availableZones: [Zone] = []
    @State private var selectedZone: Zone?
    @State private var externalZoneId = ""
    @State private var isLoadingZones = false
    
    @State private var vehiclePlate = ""
    @State private var vehicleState = ""
    @State private var vehicleCountry = "US"
    @State private var spaceNumber = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var accountId = ""
    @State private var parkingFee = "1.25"
    @State private var convenienceFee = "0.25"
    @State private var tax = "0.10"
    @State private var currencyCode = "USD"
    @State private var rateName = ""
    
    // Extend/Stop fields
    @State private var selectedSession: ParkingSession?
    @State private var newEndTime = Date()
    @State private var totalParkingFee = "2.50"
    @State private var totalConvenienceFee = "0.50"
    @State private var totalTax = "0.20"
    
    enum EventTab: String, CaseIterable {
        case start = "Start"
        case extend = "Extend"
        case stop = "Stop"
    }
    
    init(apiService: PassportAPIService, modelContext: ModelContext) {
        let vm = ParkingSessionEventViewModel(apiService: apiService, modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                // No sessions: Show start form directly
                startFormView
            } else {
                // Has sessions: Show sessions list with start button
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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearMessages() }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") { viewModel.clearMessages() }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
        .overlay {
            if viewModel.isLoading {
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
                Button(action: submitStartSession) {
                    Label("Start Parking Session", systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                    .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                .disabled(!isStartFormValid)
                    .opacity(isStartFormValid ? 1.0 : 0.5)
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
                    
                    ForEach(viewModel.sessions.filter { $0.isActive }) { session in
                        sessionCard(session)
                    }
                    
                    if !viewModel.sessions.filter({ !$0.isActive }).isEmpty {
                        Text("Completed Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        ForEach(viewModel.sessions.filter { !$0.isActive }) { session in
                            sessionCard(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .sheet(item: $sessionDetailModal) { session in
            NavigationStack {
                sessionDetailView(session)
            }
        }
    }
    
    @ViewBuilder
    private func sessionCard(_ session: ParkingSession) -> some View {
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
            if session.isActive {
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
                viewModel.deleteSession(session)
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
                    DatePicker("End Time", selection: $newEndTime)
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
                            let fees = EventFees(parkingFee: parkingFee, convenienceFee: convenienceFee, tax: tax, currencyCode: currencyCode)
                            let totalFees = EventFees(parkingFee: totalParkingFee, convenienceFee: totalConvenienceFee, tax: totalTax, currencyCode: currencyCode)
                            
                            try await viewModel.publishExtendedEvent(
                                session: session, newEndTime: newEndTime, eventFees: fees,
                                totalSessionFees: totalFees, accountId: accountId.isEmpty ? nil : accountId,
                                rateName: rateName.isEmpty ? nil : rateName, locationDetails: nil, payment: nil
                            )
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
                    DatePicker("End Time", selection: $newEndTime)
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
                            let fees = EventFees(parkingFee: parkingFee, convenienceFee: convenienceFee, tax: tax, currencyCode: currencyCode)
                            let totalFees = EventFees(parkingFee: totalParkingFee, convenienceFee: totalConvenienceFee, tax: totalTax, currencyCode: currencyCode)
                            
                            try await viewModel.publishStoppedEvent(
                                session: session, endTime: newEndTime, eventFees: fees,
                                totalSessionFees: totalFees, accountId: accountId.isEmpty ? nil : accountId,
                                rateName: rateName.isEmpty ? nil : rateName, locationDetails: nil, payment: nil
                            )
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
            TextField("0.00", text: $parkingFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Convenience")
            Spacer()
            TextField("0.00", text: $convenienceFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Tax")
            Spacer()
            TextField("0.00", text: $tax)
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
            TextField("0.00", text: $totalParkingFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Convenience")
            Spacer()
            TextField("0.00", text: $totalConvenienceFee)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
        
        HStack {
            Text("Tax")
            Spacer()
            TextField("0.00", text: $totalTax)
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
                Button(action: { previewSessionId = ParkingSession.generateSessionId() }) {
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
                Text(previewSessionId)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = previewSessionId
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
                Picker("Select Operator", selection: $selectedOperator) {
                    Text("Choose operator...").tag(nil as Operator?)
                    ForEach(operators) { op in
                        Text(op.name).tag(op as Operator?)
                    }
                }
                .onChange(of: selectedOperator) { _, newOperator in
                    if let op = newOperator {
                        loadZonesForOperator(op)
                    } else {
                        availableZones = []
                        selectedZone = nil
                    }
                }
                
                if let op = selectedOperator {
                    LabeledContent("Operator ID", value: op.id)
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
            }
        }
        .listRowBackground(Color.glassBackground)
        
        if selectedOperator != nil {
            Section(header: Text("Zone").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
                Toggle("Use External Zone ID", isOn: $useExternalZoneId)
                    .onChange(of: useExternalZoneId) { _, _ in
                        selectedZone = nil
                        externalZoneId = ""
                    }
                
                if useExternalZoneId {
                    TextField("External Zone ID", text: $externalZoneId, prompt: Text("Zone identifier"))
                        .autocapitalization(.none)
                } else {
                    if isLoadingZones {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading zones...")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                    } else if availableZones.isEmpty {
                        Text("No zones available for this operator")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .font(.caption)
                    } else {
                        Picker("Select Zone", selection: $selectedZone) {
                            Text("Choose zone...").tag(nil as Zone?)
                            ForEach(availableZones) { zone in
                                Text("\(zone.name) (\(zone.number))").tag(zone as Zone?)
                            }
                        }
                        
                        if let zone = selectedZone {
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
                Button(action: generateRandomVehicle) {
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
            
            TextField("License Plate", text: $vehiclePlate, prompt: Text("ABC1234"))
                .autocapitalization(.allCharacters)
            
            HStack {
                TextField("State Code", text: $vehicleState, prompt: Text("CA"))
                    .autocapitalization(.allCharacters)
                
                TextField("Country Code", text: $vehicleCountry, prompt: Text("US"))
                    .autocapitalization(.allCharacters)
            }
            
            TextField("Space Number (Optional)", text: $spaceNumber, prompt: Text("1-50"))
        }
        .listRowBackground(Color.glassBackground)
        
        Section(header: Text("Session Times").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
            DatePicker("Start Time", selection: $startTime)
            
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("End Time", selection: $endTime)
                
                HStack(spacing: 8) {
                    Text("Quick Duration:")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    Button("30m") {
                        endTime = startTime.addingTimeInterval(1800)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("1h") {
                        endTime = startTime.addingTimeInterval(3600)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("2h") {
                        endTime = startTime.addingTimeInterval(7200)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("4h") {
                        endTime = startTime.addingTimeInterval(14400)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                    .controlSize(.mini)
                    
                    Button("8h") {
                        endTime = startTime.addingTimeInterval(28800)
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
                Button(action: generateRandomFees) {
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
                TextField("Amount", text: $parkingFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Convenience Fee")
                Spacer()
                TextField("Amount", text: $convenienceFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                TextField("Amount", text: $tax)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Currency Code")
                Spacer()
                TextField("USD", text: $currencyCode)
                    .autocapitalization(.allCharacters)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .listRowBackground(Color.glassBackground)
        
        Section(header: Text("Optional").foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))) {
            TextField("Account ID", text: $accountId, prompt: Text("User account UUID"))
                .autocapitalization(.none)
            
            TextField("Rate Name", text: $rateName, prompt: Text("e.g., $1.25/hour"))
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
    
    // MARK: - Actions
    
    private func generateRandomVehicle() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        
        // Generate random plate (3 letters + 4 numbers)
        let randomLetters = String((0..<3).map { _ in letters.randomElement()! })
        let randomNumbers = String((0..<4).map { _ in numbers.randomElement()! })
        vehiclePlate = randomLetters + randomNumbers
        
        // Random US state
        let states = ["CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI", 
                      "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI",
                      "CO", "MN", "SC", "AL", "LA", "KY", "OR", "OK", "CT", "UT"]
        vehicleState = states.randomElement()!
        
        vehicleCountry = "US"
        
        // Random space number (optional, 50% chance) - integer between 1-50
        if Bool.random() {
            spaceNumber = String(Int.random(in: 1...50))
        } else {
            spaceNumber = ""
        }
    }
    
    private func generateRandomFees() {
        // Generate realistic parking fees
        let parkingAmounts = ["0.50", "1.00", "1.25", "1.50", "2.00", "2.50", "3.00", "4.00", "5.00"]
        parkingFee = parkingAmounts.randomElement()!
        
        // Convenience fee typically 10-20% of parking or fixed small amount
        let convenienceAmounts = ["0.25", "0.35", "0.50", "0.75"]
        convenienceFee = convenienceAmounts.randomElement()!
        
        // Tax typically small percentage
        let taxAmounts = ["0.10", "0.15", "0.20", "0.25", "0.30"]
        tax = taxAmounts.randomElement()!
        
        currencyCode = "USD"
    }
    
    private func loadZonesForOperator(_ op: Operator) {
        Task {
            isLoadingZones = true
            do {
                availableZones = try await apiService.fetchZones(forOperatorId: op.id)
            } catch {
                print("Failed to load zones: \(error)")
                availableZones = []
            }
            isLoadingZones = false
        }
    }
    
    private func submitStartSession() {
        guard let op = selectedOperator else { return }
        
        let operatorId = op.id
        let zoneIdType: ZoneIDType = useExternalZoneId ? .external : .passport
        let zoneId: String = useExternalZoneId ? externalZoneId : (selectedZone?.id ?? "")
        let zoneName: String? = useExternalZoneId ? nil : selectedZone?.name
        
        Task {
            do {
                let fees = EventFees(
                    parkingFee: parkingFee,
                    convenienceFee: convenienceFee,
                    tax: tax,
                    currencyCode: currencyCode
                )
                
                try await viewModel.publishStartedEvent(
                    sessionId: previewSessionId,
                    operatorId: operatorId,
                    zoneIdType: zoneIdType,
                    zoneId: zoneId,
                    zoneName: zoneName,
                    vehiclePlate: vehiclePlate,
                    vehicleState: vehicleState,
                    vehicleCountry: vehicleCountry,
                    spaceNumber: spaceNumber.isEmpty ? nil : spaceNumber,
                    startTime: startTime,
                    endTime: endTime,
                    accountId: accountId.isEmpty ? nil : accountId,
                    eventFees: fees,
                    rateName: rateName.isEmpty ? nil : rateName,
                    locationDetails: nil,
                    payment: nil
                )
                clearStartForm()
                // Generate new session ID for next session
                previewSessionId = ParkingSession.generateSessionId()
                // Close the sheet if it's open
                showingStartForm = false
            } catch {}
        }
    }
    
    private var isStartFormValid: Bool {
        guard selectedOperator != nil else { return false }
        
        let hasValidZone = useExternalZoneId ? !externalZoneId.isEmpty : selectedZone != nil
        
        return hasValidZone &&
        !vehiclePlate.isEmpty &&
        !vehicleState.isEmpty &&
        !parkingFee.isEmpty &&
        !convenienceFee.isEmpty &&
        !tax.isEmpty &&
        !currencyCode.isEmpty &&
        endTime > startTime
    }
    
    private func clearStartForm() {
        selectedOperator = nil
        selectedZone = nil
        externalZoneId = ""
        availableZones = []
        useExternalZoneId = false
        vehiclePlate = ""
        vehicleState = ""
        vehicleCountry = "US"
        spaceNumber = ""
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        accountId = ""
        parkingFee = "1.25"
        convenienceFee = "0.25"
        tax = "0.10"
        currencyCode = "USD"
        rateName = ""
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ParkingSession.self, Operator.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    return NavigationStack {
        ParkingSessionEventView(
            apiService: PassportAPIService(
                config: OAuthConfiguration(
                    tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
                    client_id: "test",
                    client_secret: "test",
                    audience: "public.api.passportinc.com",
                    clientTraceId: "test"
                )
            ),
            modelContext: container.mainContext
        )
        .environmentObject(PassportAPIService(
            config: OAuthConfiguration(
                tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
                client_id: "test",
                client_secret: "test",
                audience: "public.api.passportinc.com",
                clientTraceId: "test"
            )
        ))
        .modelContainer(container)
    }
}
