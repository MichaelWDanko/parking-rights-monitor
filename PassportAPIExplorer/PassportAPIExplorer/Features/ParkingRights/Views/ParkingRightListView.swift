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

    let zone: Zone
    let operatorId: String
    
    @State private var viewModel: ParkingRightListViewModel?
    
    var body: some View {
        Group {
            if let vm = viewModel {
                @Bindable var bindableViewModel: ParkingRightListViewModel = vm
                
                VStack(spacing: 0) {
                    // Search bar for filtering parking rights
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        
                        TextField("Filter parking rights...", text: $bindableViewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        if !bindableViewModel.searchText.isEmpty {
                            Button(action: {
                                bindableViewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                        }
                    }
                    .adaptiveGlassmorphismTextField()
                    .padding(.horizontal)
                    .padding(.bottom, 2)
                    
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
                    } else if bindableViewModel.filteredRights.isEmpty && !bindableViewModel.searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            Text("No parking rights found")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text("Try adjusting your search terms")
                                .font(.subheadline)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .adaptiveGlassmorphismCard()
                        .padding()
                    } else if bindableViewModel.parkingRights.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "car")
                                .font(.system(size: 50))
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            Text("No parking rights available")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            Text("This zone doesn't have any active parking rights")
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
                newViewModel.loadParkingRights()
                viewModel = newViewModel
            }
        }
        .adaptiveGlassmorphismBackground()
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveGlassmorphismNavigation()

    } // End of `body`
} // End of ParkingRightListView

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
