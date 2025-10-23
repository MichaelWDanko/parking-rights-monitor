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
            VStack {
                Text("Choose a zone")
                    .padding(.top)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
            }
            
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
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No zones available")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("This operator doesn't have any zones configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel?.filteredZones ?? []) { zone in
                        NavigationLink(destination: ParkingRightListView(zone: zone)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(zone.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Zone #\(zone.number)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(selectedOperator.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel?.loadZones()
                }) {
                    Image(systemName: "arrow.clockwise.circle")
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
    
    OperatorView(selectedOperator: charlotte)
        .environmentObject(mockAPIService)
}
