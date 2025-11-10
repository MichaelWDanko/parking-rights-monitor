//
//  OperatorView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct OperatorView: View {
    var selectedOperator: Operator
    var selectedZone: Zone?
    
    @EnvironmentObject var passportAPIService: PassportAPIService
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: OperatorViewModel?
    @State private var searchMode: SearchMode = .zoneBased
    @State private var isSearchExpanded: Bool = false
    @State private var spaceNumber: String = ""
    @State private var vehiclePlate: String = ""
    @State private var vehicleState: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Parking Rights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Subheader: Search method
            VStack(alignment: .leading, spacing: 4) {
                Text("Search method")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Search mode selector - 2-tab selector
            Picker("Search Mode", selection: $searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .onChange(of: searchMode) { _, _ in
                // Clear search fields when switching modes
                spaceNumber = ""
                vehiclePlate = ""
                vehicleState = ""
            }
            
            if searchMode == .zoneBased {
                // Subheader: Select a zone
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select a zone")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                if viewModel?.isLoadingZones == true {
                    LoadingStateView(message: "Loading zones...")
                } else if let error = viewModel?.zonesError {
                    ErrorStateView(
                        title: "Failed to load zones",
                        message: error,
                        retryAction: { viewModel?.loadZones() }
                    )
                } else if (viewModel?.filteredZones.isEmpty ?? true) && !(viewModel?.searchText.isEmpty ?? true) {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No zones found",
                        message: "Try adjusting your search terms"
                    )
                } else if (viewModel?.zones.isEmpty ?? true) {
                    EmptyStateView(
                        icon: "location.slash",
                        title: "No zones available",
                        message: "This operator doesn't have any zones configured",
                        actionTitle: "Refresh",
                        action: {
                            viewModel?.loadZones()
                        },
                        secondaryActionTitle: "Search",
                        secondaryAction: { viewModel?.loadZones() }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel?.filteredZones ?? []) { zone in
                                ZoneCardView(zone: zone, operatorId: selectedOperator.id, colorScheme: colorScheme)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Padding for floating filter
                    }
                    .refreshable {
                        await refreshZones()
                    }
                }
            } else {
                // Space/Vehicle mode: Show empty space (form is in bottom floating section)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Floating filter/search section at bottom
            if searchMode == .zoneBased {
                // Floating zone filter (always visible)
                FloatingZoneFilterSection(
                    searchText: Binding(
                        get: { viewModel?.searchText ?? "" },
                        set: { viewModel?.searchText = $0 }
                    ),
                    colorScheme: colorScheme
                )
            } else {
                // Space/Vehicle search section (always visible, no expand/collapse)
                OperatorSearchSection(
                    searchMode: $searchMode,
                    isExpanded: $isSearchExpanded,
                    spaceNumber: $spaceNumber,
                    vehiclePlate: $vehiclePlate,
                    vehicleState: $vehicleState,
                    operatorId: selectedOperator.id,
                    colorScheme: colorScheme,
                    passportAPIService: passportAPIService
                )
            }
        }
        .navigationTitle(selectedOperator.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .adaptiveGlassmorphismNavigation()
        .adaptiveGlassmorphismBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel?.sortOption = option
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if viewModel?.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        Task {
                            await refreshZones()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OperatorViewModel(
                    selectedOperator: selectedOperator,
                    passportAPIService: passportAPIService
                )
            }
            viewModel?.loadZones()
        }
    }
    
    private func refreshZones() async {
        await MainActor.run {
            viewModel?.loadZones()
        }
    }
}

struct ZoneCardView: View {
    let zone: Zone
    let operatorId: String
    let colorScheme: ColorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: ParkingRightListView(zone: zone, operatorId: operatorId)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zone.name)
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .multilineTextAlignment(.leading)
                    Text("Zone #\(zone.number)")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .adaptiveGlassmorphismListRow()
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Floating Zone Filter Section Component (always visible for zone-based filtering)
// Styled like native iOS floating search bar (e.g., Apple Music)
struct FloatingZoneFilterSection: View {
    @Binding var searchText: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Main search bar - wide, rounded rectangle
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                
                TextField("Filter zones", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: colorScheme == .dark ? [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ] : [
                                        Color.black.opacity(0.1),
                                        Color.black.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    let mockAPIService = PreviewEnvironment.makePreviewService()
    
    OperatorView(selectedOperator: zdanko)
        .environmentObject(mockAPIService)
}

// Operator Search Section Component
struct OperatorSearchSection: View {
    @Binding var searchMode: SearchMode
    @Binding var isExpanded: Bool
    @Binding var spaceNumber: String
    @Binding var vehiclePlate: String
    @Binding var vehicleState: String
    let operatorId: String
    let colorScheme: ColorScheme
    let passportAPIService: PassportAPIService
    
    private var canSearch: Bool {
        switch searchMode {
        case .zoneBased:
            return true // Zone selection is always available
        case .spaceVehicleBased:
            return !spaceNumber.trimmingCharacters(in: .whitespaces).isEmpty ||
                   !vehiclePlate.trimmingCharacters(in: .whitespaces).isEmpty ||
                   !vehicleState.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Space/Vehicle mode: Three text fields - always visible
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "car")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .frame(width: 24)
                    
                    TextField("Vehicle Plate", text: $vehiclePlate)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .autocapitalization(.allCharacters)
                }
                .adaptiveGlassmorphismTextField()
                
                HStack(spacing: 12) {
                    Image(systemName: "map")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .frame(width: 24)
                    
                    TextField("Vehicle State (ISO 3166-2)", text: $vehicleState)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .autocapitalization(.allCharacters)
                }
                .adaptiveGlassmorphismTextField()
                
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .frame(width: 24)
                    
                    TextField("Space Number", text: $spaceNumber)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .autocapitalization(.none)
                }
                .adaptiveGlassmorphismTextField()
            }
            .padding(.horizontal, 20)
            
            // Search button
            NavigationLink(
                destination: ParkingRightListView(
                    zone: nil,
                    operatorId: operatorId,
                    initialSearchMode: .spaceVehicleBased,
                    initialSpaceNumber: spaceNumber,
                    initialVehiclePlate: vehiclePlate,
                    initialVehicleState: vehicleState
                )
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
            .disabled(!canSearch)
            .opacity(canSearch ? 1.0 : 0.6)
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
        .adaptiveFloatingSearchSection(isExpanded: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
