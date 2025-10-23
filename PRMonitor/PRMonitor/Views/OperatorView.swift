//
//  OperatorView.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/6/25.
//

import SwiftUI

struct OperatorView: View {
    var selectedOperator: Operator
    var selectedZone: Zone?
    
    @EnvironmentObject var passportAPIService: PassportAPIService
    @State private var viewModel: OperatorViewModel?
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a zone")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                
                Text("Select a zone to view parking rights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal)
            
            // Search bar for filtering zones
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search by name or number...", text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ))
                .textFieldStyle(PlainTextFieldStyle())
                
                if !(viewModel?.searchText.isEmpty ?? true) {
                    Button(action: {
                        viewModel?.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if viewModel?.isLoadingZones == true {
                ProgressView("Loading zones...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel?.zonesError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Failed to load zones")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel?.loadZones()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if (viewModel?.filteredZones.isEmpty ?? true) && !(viewModel?.searchText.isEmpty ?? true) {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No zones found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Try adjusting your search terms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if (viewModel?.zones.isEmpty ?? true) {
                VStack(spacing: 20) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No zones available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("This operator doesn't have any zones configured")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        
                        Button(action: {
                            viewModel?.loadZones()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel?.filteredZones ?? []) { zone in
                            NavigationLink(destination: ParkingRightListView(zone: zone)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(zone.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        Text("Zone #\(zone.number)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .refreshable {
                    await refreshZones()
                }
            }
        }
        .navigationTitle(selectedOperator.name)
        .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    let secrets = try! SecretsLoader.load()
    let config = OAuthConfiguration(
        tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
        client_id: secrets.client_id,
        client_secret: secrets.client_secret,
        audience: "public.api.passportinc.com",
        clientTraceId: "danko-test"
    )
    let mockAPIService = PassportAPIService(config: config)
    
    OperatorView(selectedOperator: zdanko)
        .environmentObject(mockAPIService)
}
