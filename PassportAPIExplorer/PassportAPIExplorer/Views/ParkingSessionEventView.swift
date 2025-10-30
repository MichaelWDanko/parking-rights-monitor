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
    
    @State private var selectedTab: EventTab = .start
    @State private var previewSessionId: String = ParkingSession.generateSessionId()
    
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
        ZStack(alignment: .bottom) {
            Form {
                Section {
                    Picker("Action", selection: $selectedTab) {
                        ForEach(EventTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTab) { _, newValue in
                        // Update button time when switching to extend/stop
                        if newValue == .extend || newValue == .stop {
                            newEndTime = Date()
                        }
                    }
                }
                
                switch selectedTab {
                case .start:
                    startSessionForm
                case .extend:
                    extendSessionForm
                case .stop:
                    stopSessionForm
                }
                
                if !viewModel.sessions.isEmpty {
                    sessionsList
                }
                
                // Add padding at bottom for floating button
                Section {
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
            }
            
            // Floating button
            floatingButton
        }
        .adaptiveGlassmorphismBackground()
        .navigationTitle("Parking Session Events")
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
    
    @ViewBuilder
    private var floatingButton: some View {
        VStack {
            switch selectedTab {
            case .start:
                Button(action: submitStartSession) {
                    Label("Start Parking Session", systemImage: "play.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isStartFormValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isStartFormValid)
                
            case .extend:
                if selectedSession != nil {
                    Button(action: submitExtendSession) {
                        Label("Extend Session", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                
            case .stop:
                if selectedSession != nil {
                    Button(action: submitStopSession) {
                        Label("Stop Session", systemImage: "stop.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Start Session Form
    
    @ViewBuilder
    private var startSessionForm: some View {
        Section {
            HStack {
                Text("Session ID Preview")
                    .font(.headline)
                Spacer()
                Button(action: { previewSessionId = ParkingSession.generateSessionId() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("New ID")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.small)
            }
            
            HStack {
                Text(previewSessionId)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = previewSessionId
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
        }
        
        Section("Operator") {
            if operators.isEmpty {
                Text("No operators available. Add an operator first.")
                    .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                }
            }
        }
        
        if selectedOperator != nil {
            Section("Zone") {
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
                                .foregroundColor(.secondary)
                        }
                    } else if availableZones.isEmpty {
                        Text("No zones available for this operator")
                            .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        
        Section {
            HStack {
                Text("Vehicle")
                    .font(.headline)
                Spacer()
                Button(action: generateRandomVehicle) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Random")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
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
        
        Section("Session Times") {
            DatePicker("Start Time", selection: $startTime)
            
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("End Time", selection: $endTime)
                
                HStack(spacing: 8) {
                    Text("Quick Duration:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("30m") {
                        endTime = startTime.addingTimeInterval(1800)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("1h") {
                        endTime = startTime.addingTimeInterval(3600)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("2h") {
                        endTime = startTime.addingTimeInterval(7200)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("4h") {
                        endTime = startTime.addingTimeInterval(14400)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("8h") {
                        endTime = startTime.addingTimeInterval(28800)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        
        Section {
            HStack {
                Text("Event Fees")
                    .font(.headline)
                Spacer()
                Button(action: generateRandomFees) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Random")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
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
        
        Section("Optional") {
            TextField("Account ID", text: $accountId, prompt: Text("User account UUID"))
                .autocapitalization(.none)
            
            TextField("Rate Name", text: $rateName, prompt: Text("e.g., $1.25/hour"))
        }
    }
    
    // MARK: - Extend Session Form
    
    @ViewBuilder
    private var extendSessionForm: some View {
        Section("Select Session") {
            if viewModel.sessions.filter({ $0.isActive }).isEmpty {
                Text("No active sessions")
                    .foregroundColor(.secondary)
            } else {
                Picker("Session", selection: $selectedSession) {
                    Text("Select...").tag(nil as ParkingSession?)
                    ForEach(viewModel.sessions.filter { $0.isActive }) { session in
                        Text("\(session.vehiclePlate) - \(session.zoneId)").tag(session as ParkingSession?)
                    }
                }
                
                if let session = selectedSession {
                    LabeledContent("Current End", value: session.endTime, format: .dateTime)
                }
            }
        }
        
        if selectedSession != nil {
            Section("New End Time") {
                DatePicker("End Time", selection: $newEndTime)
            }
            
            Section("Extension Fees") {
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
            
            Section("Total Session Fees") {
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
        }
    }
    
    // MARK: - Stop Session Form
    
    @ViewBuilder
    private var stopSessionForm: some View {
        Section("Select Session") {
            if viewModel.sessions.filter({ $0.isActive }).isEmpty {
                Text("No active sessions")
                    .foregroundColor(.secondary)
            } else {
                Picker("Session", selection: $selectedSession) {
                    Text("Select...").tag(nil as ParkingSession?)
                    ForEach(viewModel.sessions.filter { $0.isActive }) { session in
                        Text("\(session.vehiclePlate) - \(session.zoneId)").tag(session as ParkingSession?)
                    }
                }
                
                if let session = selectedSession {
                    LabeledContent("Vehicle", value: "\(session.vehiclePlate) (\(session.vehicleState))")
                    LabeledContent("Zone", value: session.zoneId)
                    LabeledContent("Started", value: session.startTime, format: .dateTime)
                }
            }
        }
        
        if selectedSession != nil {
            Section("Actual End Time") {
                DatePicker("End Time", selection: $newEndTime)
            }
            
            Section("Stop Event Fees") {
                Text("Can be negative for refunds")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Parking")
                    Spacer()
                    TextField("0.00", text: $parkingFee)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Convenience")
                    Spacer()
                    TextField("0.00", text: $convenienceFee)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Tax")
                    Spacer()
                    TextField("0.00", text: $tax)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Section("Total Session Fees") {
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
        }
    }
    
    // MARK: - Sessions List
    
    @ViewBuilder
    private var sessionsList: some View {
        Section("All Sessions") {
            ForEach(viewModel.sessions) { session in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(session.vehiclePlate) (\(session.vehicleState))")
                            .font(.headline)
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
                    
                    Text("Zone: \(session.zoneId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(session.startTime.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "clock")
                        Spacer()
                        Label(session.endTime.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "clock.badge.checkmark")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Action buttons for active sessions
                    if session.isActive {
                        HStack(spacing: 12) {
                            Button(action: {
                                selectedSession = session
                                selectedTab = .extend
                            }) {
                                Label("Extend", systemImage: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
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
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteSession(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    if session.isActive {
                        Button {
                            selectedSession = session
                            selectedTab = .extend
                        } label: {
                            Label("Extend", systemImage: "clock.arrow.circlepath")
                        }
                        .tint(.blue)
                        
                        Button {
                            selectedSession = session
                            selectedTab = .stop
                        } label: {
                            Label("Stop", systemImage: "stop.circle")
                        }
                        .tint(.red)
                    }
                }
            }
        }
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
            } catch {}
        }
    }
    
    private func submitExtendSession() {
        guard let session = selectedSession else { return }
        Task {
            do {
                let fees = EventFees(
                    parkingFee: parkingFee,
                    convenienceFee: convenienceFee,
                    tax: tax,
                    currencyCode: currencyCode
                )
                
                let totalFees = EventFees(
                    parkingFee: totalParkingFee,
                    convenienceFee: totalConvenienceFee,
                    tax: totalTax,
                    currencyCode: currencyCode
                )
                
                try await viewModel.publishExtendedEvent(
                    session: session,
                    newEndTime: newEndTime,
                    eventFees: fees,
                    totalSessionFees: totalFees,
                    accountId: accountId.isEmpty ? nil : accountId,
                    rateName: rateName.isEmpty ? nil : rateName,
                    locationDetails: nil,
                    payment: nil
                )
                selectedSession = nil
            } catch {}
        }
    }
    
    private func submitStopSession() {
        guard let session = selectedSession else { return }
        Task {
            do {
                let fees = EventFees(
                    parkingFee: parkingFee,
                    convenienceFee: convenienceFee,
                    tax: tax,
                    currencyCode: currencyCode
                )
                
                let totalFees = EventFees(
                    parkingFee: totalParkingFee,
                    convenienceFee: totalConvenienceFee,
                    tax: totalTax,
                    currencyCode: currencyCode
                )
                
                try await viewModel.publishStoppedEvent(
                    session: session,
                    endTime: newEndTime,
                    eventFees: fees,
                    totalSessionFees: totalFees,
                    accountId: accountId.isEmpty ? nil : accountId,
                    rateName: rateName.isEmpty ? nil : rateName,
                    locationDetails: nil,
                    payment: nil
                )
                selectedSession = nil
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
