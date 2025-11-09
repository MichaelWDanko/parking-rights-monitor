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
            // Section header - only show for zone-based mode
            if searchMode == .zoneBased {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a zone")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                    
                    Text("Select a zone to view parking rights")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                .adaptiveGlassmorphismCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Search bar for filtering zones
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    TextField("Search by name or number...", text: Binding(
                        get: { viewModel?.searchText ?? "" },
                        set: { viewModel?.searchText = $0 }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    if !(viewModel?.searchText.isEmpty ?? true) {
                        Button(action: {
                            viewModel?.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                    }
                }
                .adaptiveGlassmorphismTextField()
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            if searchMode == .zoneBased {
                if viewModel?.isLoadingZones == true {
                    ProgressView("Loading zones...")
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel?.zonesError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.cyanAccent)
                        Text("Failed to load zones")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel?.loadZones()
                        }
                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .adaptiveGlassmorphismCard()
                    .padding()
                } else if (viewModel?.filteredZones.isEmpty ?? true) && !(viewModel?.searchText.isEmpty ?? true) {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        Text("No zones found")
                            .font(.headline)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .adaptiveGlassmorphismCard()
                    .padding()
                } else if (viewModel?.zones.isEmpty ?? true) {
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 50))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        
                        VStack(spacing: 8) {
                            Text("No zones available")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text("This operator doesn't have any zones configured")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                viewModel?.loadZones()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                    Text("Refresh")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                            
                            Button(action: {
                                viewModel?.loadZones()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: false))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .adaptiveGlassmorphismCard()
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel?.filteredZones ?? []) { zone in
                                ZoneCardView(zone: zone, operatorId: selectedOperator.id, colorScheme: colorScheme)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, isSearchExpanded ? 320 : 120) // Extra padding to prevent overlap
                    }
                    .refreshable {
                        await refreshZones()
                    }
                }
            } else {
                // Space/Vehicle mode: Show empty state prompting user to use search
                VStack(spacing: 20) {
                    Image(systemName: "car")
                        .font(.system(size: 50))
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    
                    Text("Search by Space or Vehicle")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    Text("Use the search options below to find parking rights by space number, vehicle plate, or vehicle state")
                        .font(.subheadline)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .adaptiveGlassmorphismCard()
                .padding()
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Floating search section at bottom
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
        VStack(spacing: 0) {
            // Collapsed/Expanded header - entire area is tappable
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Search Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 20) {
                    // Search mode selector
                    Picker("Search Mode", selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .onChange(of: searchMode) { _, _ in
                        // Clear search fields when switching modes
                        spaceNumber = ""
                        vehiclePlate = ""
                        vehicleState = ""
                    }
                    
                    // Conditional input fields based on search mode
                    Group {
                        if searchMode == .zoneBased {
                            // Zone-based: Show message that zones are listed above
                            Text("Select a zone from the list above to view parking rights")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                        } else {
                            // Space/Vehicle mode: Three text fields
                            VStack(spacing: 16) {
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
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Search button
                    if searchMode == .spaceVehicleBased {
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
                        .padding(.bottom, 4)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .adaptiveFloatingSearchSection(isExpanded: isExpanded)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
