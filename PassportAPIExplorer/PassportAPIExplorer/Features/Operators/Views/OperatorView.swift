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
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
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
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await refreshZones()
                }
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

#Preview {
    let mockAPIService = PreviewEnvironment.makePreviewService()
    
    OperatorView(selectedOperator: zdanko)
        .environmentObject(mockAPIService)
}
