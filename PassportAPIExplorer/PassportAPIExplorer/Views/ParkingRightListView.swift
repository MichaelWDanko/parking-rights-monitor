//
//  ParkingRightListView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct ParkingRightListView: View {
    
    let zone: Zone
    let operatorId: String
    @EnvironmentObject var passportAPIService: PassportAPIService
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchText = ""
    @State private var parkingRights: [ParkingRight] = []
    @State private var isLoadingRights = false
    @State private var rightsError: String?
    
    // Computed property to filter parking rights based on search text
    private var filteredRights: [ParkingRight] {
        if searchText.isEmpty {
            return parkingRights
        } else {
            return parkingRights.filter { parkingRight in
                parkingRight.vehicle_plate?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.space_number?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.vehicle_state?.localizedCaseInsensitiveContains(searchText) == true ||
                parkingRight.reference_id?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func loadParkingRights() {
        print("🚗 Starting to load parking rights for zone: \(zone.name) (ID: \(zone.id))")
        isLoadingRights = true
        rightsError = nil
        
        Task {
            do {
                print("🚗 Calling API service to fetch parking rights...")
                let fetchedRights = try await passportAPIService.fetchParkingRights(
                    forOperatorId: operatorId,
                    zoneId: zone.id
                )
                print("🚗 API service returned \(fetchedRights.count) parking rights")
                for (index, right) in fetchedRights.enumerated() {
                    print("🚗 Parking Right \(index + 1): \(right.id)")
                    print("🚗   - Vehicle: \(right.vehicle_plate ?? "N/A") (\(right.vehicle_state ?? "N/A"))")
                    print("🚗   - Time: \(right.start_time) to \(right.end_time)")
                    print("🚗   - Reference: \(right.reference_id ?? "N/A")")
                }
                await MainActor.run {
                    parkingRights = fetchedRights
                    isLoadingRights = false
                    print("🚗 Updated parkingRights array with \(parkingRights.count) items")
                }
            } catch {
                print("🚗 Error loading parking rights: \(error)")
                await MainActor.run {
                    rightsError = error.localizedDescription
                    isLoadingRights = false
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar for filtering parking rights
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                
                TextField("Filter parking rights...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
            }
            .adaptiveGlassmorphismTextField()
            .padding(.horizontal)
            .padding(.bottom, 2)
            
            if isLoadingRights {
                ProgressView("Loading parking rights...")
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = rightsError {
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
                        loadParkingRights()
                    }
                    .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .adaptiveGlassmorphismCard()
                .padding()
            } else if filteredRights.isEmpty && !searchText.isEmpty {
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
            } else if parkingRights.isEmpty {
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
                List(filteredRights) { parkingRight in
                    ParkingRightView(pr: parkingRight)
                }
                .scrollContentBackground(.hidden)
                .onAppear {
                    print("🚗 UI: Displaying \(filteredRights.count) parking rights")
                    for (index, right) in filteredRights.enumerated() {
                        print("🚗 UI: Item \(index + 1): \(right.vehicle_plate ?? "N/A")")
                    }
                }
            }
        }
        .adaptiveGlassmorphismBackground()
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .glassmorphismNavigation()
        .onAppear {
            loadParkingRights()
        }
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
    
    let secrets = try! SecretsLoader.load()
    let config = OAuthConfiguration(
        tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
        client_id: secrets.client_id,
        client_secret: secrets.client_secret,
        audience: "public.api.passportinc.com",
        clientTraceId: "danko-test"
    )
    let mockAPIService = PassportAPIService(config: config)
    
    ParkingRightListView(zone: sampleZone, operatorId: zdanko.id)
        .environmentObject(mockAPIService)
}
