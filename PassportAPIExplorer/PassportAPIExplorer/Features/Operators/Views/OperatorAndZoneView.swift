//
//  OperatorAndZoneView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI
import SwiftData

/// Unified view that combines operator selection and zone display for iPhone
/// Replaces the complex OperatorDrawer + OperatorZoneView architecture
struct OperatorAndZoneView: View {
    @Query private var operators: [Operator]
    @EnvironmentObject var passportAPIService: PassportAPIService
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    
    // Operator selection state
    @State private var selectedOperator: Operator?
    @State private var isOperatorListVisible: Bool = false
    
    // Zone view state
    @State private var viewModel: OperatorZoneView.OperatorViewModel?
    @State private var searchMode: SearchMode = .zoneBased
    @State private var isSearchExpanded: Bool = false
    @State private var spaceNumber: String = ""
    @State private var vehiclePlate: String = ""
    @State private var vehicleState: String = ""
    
    // Gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    let operatorListWidth: CGFloat = 280
    let edgePanWidth: CGFloat = 30
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main content - Zone view
            if let selectedOp = selectedOperator {
                zoneContentView(for: selectedOp)
                    .disabled(isOperatorListVisible)
            } else {
                // No operator selected - show empty state
                emptyStateView
            }
            
            // Dimming overlay when operator list is visible
            if isOperatorListVisible {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isOperatorListVisible = false
                        }
                    }
            }
            
            // Operator list overlay
            operatorListOverlay
                .offset(x: operatorListOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOperatorListVisible)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
                .highPriorityGesture(closeDrawerGesture)
            
            // Edge pan gesture area (invisible) - only when list is hidden
            if !isOperatorListVisible {
                Color.clear
                    .frame(width: edgePanWidth)
                    .contentShape(Rectangle())
                    .gesture(edgePanGesture)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            // Auto-open operator list if no operator is selected
            if selectedOperator == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isOperatorListVisible = true
                    }
                }
            }
        }
    }
    
    // MARK: - Zone Content View
    
    @ViewBuilder
    private func zoneContentView(for op: Operator) -> some View {
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
            
            // Search mode selector
            Picker("Search Mode", selection: $searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .onChange(of: searchMode) { _, _ in
                spaceNumber = ""
                vehiclePlate = ""
                vehicleState = ""
            }
            
            if searchMode == .zoneBased {
                // Zone-based content
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
                        action: { viewModel?.loadZones() }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel?.filteredZones ?? []) { zone in
                                ZoneCardView(zone: zone, operatorId: op.id, colorScheme: colorScheme)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refreshZones()
                    }
                }
            } else {
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if searchMode == .zoneBased {
                FloatingZoneFilterSection(
                    searchText: Binding(
                        get: { viewModel?.searchText ?? "" },
                        set: { viewModel?.searchText = $0 }
                    ),
                    colorScheme: colorScheme
                )
            } else {
                OperatorSearchSection(
                    searchMode: $searchMode,
                    isExpanded: $isSearchExpanded,
                    spaceNumber: $spaceNumber,
                    vehiclePlate: $vehiclePlate,
                    vehicleState: $vehicleState,
                    operatorId: op.id,
                    colorScheme: colorScheme,
                    passportAPIService: passportAPIService
                )
            }
        }
        .navigationTitle(op.name)
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveGlassmorphismNavigation()
        .adaptiveGlassmorphismBackground()
        .toolbar {
            // Hamburger menu on leading side - only show when drawer is closed
            if !isOperatorListVisible {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isOperatorListVisible = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    }
                }
            }
            
            // Sort/refresh menu on trailing side - only show when drawer is closed
            if !isOperatorListVisible {
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
        }
        .onChange(of: selectedOperator) { _, newOperator in
            if let newOperator = newOperator {
                viewModel = OperatorZoneView.OperatorViewModel(
                    selectedOperator: newOperator,
                    passportAPIService: passportAPIService
                )
                viewModel?.loadZones()
            }
        }
        .onAppear {
            if viewModel == nil, let selectedOperator = selectedOperator {
                viewModel = OperatorZoneView.OperatorViewModel(
                    selectedOperator: selectedOperator,
                    passportAPIService: passportAPIService
                )
                viewModel?.loadZones()
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack {
            Color.clear
                .adaptiveGlassmorphismBackground()
        }
        .navigationTitle("Parking Rights")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveGlassmorphismNavigation()
    }
    
    // MARK: - Operator List Overlay
    
    private var operatorListOverlay: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with safe area
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    HStack {
                        Text("Operators")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isOperatorListVisible = false
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.adaptiveTextSecondary(colorScheme == .dark).opacity(0.15))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .background(Color.adaptiveTextSecondary(colorScheme == .dark).opacity(0.3))
                        .padding(.horizontal, 20)
                }
                
                // Operator list content
                OperatorListContent(
                    onSelectOperator: { op in
                        selectedOperator = op
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isOperatorListVisible = false
                        }
                    },
                    isIPhone: true,
                    selectedOperatorId: .constant(selectedOperator?.id)
                )
            }
            .frame(width: operatorListWidth)
            .background(
                ZStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.navyBlue : Color.white)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.adaptiveCyanAccent(colorScheme == .dark).opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.15),
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 1)
                    }
                }
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 5, y: 0)
                .shadow(color: Color.cyanAccent.opacity(0.15), radius: 25, x: 5, y: 0)
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    // MARK: - Computed Properties
    
    private var operatorListOffset: CGFloat {
        if isDragging {
            return dragOffset
        }
        return isOperatorListVisible ? 0 : -operatorListWidth
    }
    
    // MARK: - Gestures
    
    private var edgePanGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if value.translation.width > 0 {
                    isDragging = true
                    let clamped = min(value.translation.width, operatorListWidth)
                    dragOffset = -operatorListWidth + clamped
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let vx = value.velocity.width
                
                let shouldOpen = dx > operatorListWidth * 0.4 || vx > 800
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isOperatorListVisible = shouldOpen
                    dragOffset = shouldOpen ? 0 : -operatorListWidth
                }
                
                isDragging = false
            }
    }
    
    private var closeDrawerGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Only respond to left swipe (closing)
                if value.translation.width < 0 {
                    isDragging = true
                    // Start from 0 (fully open) and move left (negative)
                    let clamped = max(value.translation.width, -operatorListWidth)
                    dragOffset = clamped
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let vx = value.velocity.width
                
                // Should close if dragged far enough or fast enough
                let shouldClose = dx < -operatorListWidth * 0.4 || vx < -800
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if shouldClose {
                        isOperatorListVisible = false
                        dragOffset = -operatorListWidth
                    } else {
                        // Snap back to open
                        isOperatorListVisible = true
                        dragOffset = 0
                    }
                }
                
                isDragging = false
            }
    }
    
    // MARK: - Helper Methods
    
    private func refreshZones() async {
        await MainActor.run {
            viewModel?.loadZones()
        }
    }
}

#Preview {
    NavigationStack {
        OperatorAndZoneView()
            .environmentObject(PreviewEnvironment.makePreviewService())
    }
    .modelContainer(for: Operator.self, inMemory: true)
}

