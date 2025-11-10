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
                        LoadingStateView(message: "Loading parking rights...")
                    } else if let error = bindableViewModel.rightsError {
                        ErrorStateView(
                            title: "Failed to load parking rights",
                            message: error,
                            retryAction: { bindableViewModel.loadParkingRights() }
                        )
                    } else if bindableViewModel.filteredRights.isEmpty {
                        let isEmptySearch = bindableViewModel.searchMode == .zoneBased && !bindableViewModel.searchText.isEmpty
                        EmptyStateView(
                            icon: isEmptySearch ? "magnifyingglass" : "car",
                            title: isEmptySearch ? "No parking rights found" : "No parking rights available",
                            message: isEmptySearch ? "Try adjusting your search terms" : (bindableViewModel.searchMode == .zoneBased ? "This zone doesn't have any active parking rights" : "Use the search below to find parking rights")
                        )
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
                    // Floating filter section at bottom - always visible for zone-based filtering
                    if bindableViewModel.searchMode == .zoneBased {
                        FloatingFilterSection(
                            viewModel: bindableViewModel,
                            colorScheme: colorScheme
                        )
                    }
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

// Floating Filter Section Component (always visible for zone-based filtering)
// Styled like native iOS floating search bar (e.g., Apple Music)
struct FloatingFilterSection: View {
    @Bindable var viewModel: ParkingRightListViewModel
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Main search bar - wide, rounded rectangle
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                
                TextField("Filter parking rights...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    .font(.system(size: 16))
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
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
