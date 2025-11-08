//
//  ParkingRightListView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ParkingRightListView: View {
    
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    
    @EnvironmentObject var passportAPIService: PassportAPIService
    @Environment(\.colorScheme) var colorScheme

    let zone: Zone?
    let operatorId: String
    let initialSearchMode: SearchMode?
    let initialSpaceNumber: String?
    let initialVehiclePlate: String?
    let initialVehicleState: String?
    
    @State private var viewModel: ParkingRightListViewModel?
    @State private var isSearchExpanded: Bool = false
    
    init(
        zone: Zone?,
        operatorId: String,
        initialSearchMode: SearchMode? = nil,
        initialSpaceNumber: String? = nil,
        initialVehiclePlate: String? = nil,
        initialVehicleState: String? = nil
    ) {
        self.zone = zone
        self.operatorId = operatorId
        self.initialSearchMode = initialSearchMode
        self.initialSpaceNumber = initialSpaceNumber
        self.initialVehiclePlate = initialVehiclePlate
        self.initialVehicleState = initialVehicleState
    }
    
    var body: some View {
        Group {
            if let vm = viewModel {
                @Bindable var bindableViewModel: ParkingRightListViewModel = vm
                
                VStack(spacing: 0) {
                    if bindableViewModel.isLoadingRights {
                        ProgressView("Loading parking rights...")
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = bindableViewModel.rightsError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.cyanAccent)
                            Text("Failed to load parking rights")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                bindableViewModel.loadParkingRights()
                            }
                            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .adaptiveGlassmorphismCard()
                        .padding()
                    } else if bindableViewModel.filteredRights.isEmpty {
                        let isEmptySearch = bindableViewModel.searchMode == .zoneBased && !bindableViewModel.searchText.isEmpty
                        VStack(spacing: 16) {
                            Image(systemName: isEmptySearch ? "magnifyingglass" : "car")
                                .font(.system(size: 50))
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            Text(isEmptySearch ? "No parking rights found" : "No parking rights available")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text(isEmptySearch ? "Try adjusting your search terms" : (bindableViewModel.searchMode == .zoneBased ? "This zone doesn't have any active parking rights" : "Use the search below to find parking rights"))
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .adaptiveGlassmorphismCard()
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(bindableViewModel.filteredRights) { parkingRight in
                                    ParkingRightView(pr: parkingRight)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                        .onAppear {
                            print("🚗 UI: Displaying \(bindableViewModel.filteredRights.count) parking rights")
                            for (index, right) in bindableViewModel.filteredRights.enumerated() {
                                print("🚗 UI: Item \(index + 1): \(right.vehicle_plate ?? "N/A")")
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // Floating search section at bottom
                    FloatingSearchSection(
                        viewModel: bindableViewModel,
                        isExpanded: $isSearchExpanded,
                        colorScheme: colorScheme
                    )
                }
            } else {
                ProgressView("Initializing...")
            }
        } // End of Group
        .task {
            if viewModel == nil {
                let newViewModel = ParkingRightListViewModel(
                    passportAPIService: passportAPIService,
                    op: operatorId,
                    z: zone
                )
                // Set initial search mode and values if provided
                if let initialSearchMode = initialSearchMode {
                    newViewModel.searchMode = initialSearchMode
                }
                if let initialSpaceNumber = initialSpaceNumber {
                    newViewModel.spaceNumber = initialSpaceNumber
                }
                if let initialVehiclePlate = initialVehiclePlate {
                    newViewModel.vehiclePlate = initialVehiclePlate
                }
                if let initialVehicleState = initialVehicleState {
                    newViewModel.vehicleState = initialVehicleState
                }
                // Auto-load if zone is provided or if we have space/vehicle search criteria
                if zone != nil || (initialSearchMode == .spaceVehicleBased && newViewModel.canSearch) {
                    newViewModel.loadParkingRights()
                }
                viewModel = newViewModel
            }
        }
        .adaptiveGlassmorphismBackground()
        .navigationTitle(zone?.name ?? "Parking Rights")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveGlassmorphismNavigation()

    } // End of `body`
} // End of ParkingRightListView

// Floating Search Section Component (for zone-based filtering only)
struct FloatingSearchSection: View {
    @Bindable var viewModel: ParkingRightListViewModel
    @Binding var isExpanded: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed/Expanded header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(viewModel.searchMode == .zoneBased ? "Filter Options" : "Search Options")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            if isExpanded {
                VStack(spacing: 16) {
                    if viewModel.searchMode == .zoneBased {
                        // Zone-based: Local filter text field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            
                            TextField("Filter parking rights...", text: $viewModel.searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                }
                            }
                        }
                        .adaptiveGlassmorphismTextField()
                        .padding(.horizontal, 16)
                    } else {
                        // Space/Vehicle mode: Show search fields and allow re-searching
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                    .frame(width: 20)
                                
                                TextField("Space Number", text: $viewModel.spaceNumber)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                    .autocapitalization(.none)
                            }
                            .adaptiveGlassmorphismTextField()
                            
                            HStack {
                                Image(systemName: "car")
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                    .frame(width: 20)
                                
                                TextField("Vehicle Plate", text: $viewModel.vehiclePlate)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                    .autocapitalization(.allCharacters)
                            }
                            .adaptiveGlassmorphismTextField()
                            
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                    .frame(width: 20)
                                
                                TextField("Vehicle State (ISO 3166-2)", text: $viewModel.vehicleState)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                    .autocapitalization(.allCharacters)
                            }
                            .adaptiveGlassmorphismTextField()
                        }
                        .padding(.horizontal, 16)
                        
                        // Search button for space/vehicle mode
                        Button(action: {
                            viewModel.loadParkingRights()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                        .disabled(!viewModel.canSearch)
                        .opacity(viewModel.canSearch ? 1.0 : 0.6)
                        .padding(.horizontal, 16)
                    }
                    
                    if viewModel.searchMode == .zoneBased {
                        // No button needed for zone-based - filtering happens automatically
                    }
                }
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .adaptiveGlassmorphismCard()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    // Create a sample zone for preview
    let sampleZone = Zone(
        id: "sample-zone-id",
        name: "Sample Zone",
        number: "S-001",
        operator_id: zdanko.id
    )
    
    let mockAPIService = PreviewEnvironment.makePreviewService()
    
    ParkingRightListView(zone: sampleZone, operatorId: zdanko.id)
        .environmentObject(mockAPIService)
}
