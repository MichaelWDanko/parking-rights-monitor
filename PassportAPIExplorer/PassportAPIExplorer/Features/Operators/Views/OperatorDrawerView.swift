//
//  OperatorDrawerView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI
import SwiftData

/// Custom drawer that slides in from the leading edge for operator selection
struct OperatorDrawer<Content: View>: View {
    @ObservedObject var viewModel: OperatorDrawerViewModel
    @Environment(\.colorScheme) var colorScheme
    @GestureState private var dragOffset: CGFloat = 0
    
    let content: Content
    let drawerWidth: CGFloat = 280
    let edgePanWidth: CGFloat = 30
    
    init(viewModel: OperatorDrawerViewModel, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main content
            content
                .disabled(viewModel.isDrawerOpen)
            
            // Dimming overlay
            if viewModel.isDrawerOpen {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Only allow closing if an operator is selected
                        if viewModel.selectedOperator != nil {
                            viewModel.closeDrawer()
                        }
                    }
                    .transition(.opacity)
            }
            
            // Drawer panel - only render when open
            if viewModel.isDrawerOpen {
                drawerPanel
                    .offset(x: dragOffset)
                    .gesture(drawerDragGesture)
                    .transition(.move(edge: .leading))
            }
            
            // Edge pan gesture area (invisible)
            if !viewModel.isDrawerOpen {
                Color.clear
                    .frame(width: edgePanWidth)
                    .contentShape(Rectangle())
                    .gesture(edgePanGesture)
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Drawer Panel
    
    private var drawerPanel: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with safe area handling
                DrawerHeader(
                    safeAreaTop: geometry.safeAreaInsets.top,
                    onAddOperator: { /* Will be handled by OperatorListContent */ }
                )
                
                // Operator list content
                OperatorListContent(
                    onSelectOperator: { op in
                        viewModel.selectOperator(op)
                    },
                    isIPhone: true,
                    selectedOperatorId: .constant(viewModel.selectedOperator?.id)
                )
            }
            .frame(width: drawerWidth)
            .background(
                ZStack {
                    // Solid background base for high contrast
                    Rectangle()
                        .fill(colorScheme == .dark ? 
                              Color.navyBlue : 
                              Color.white
                        )
                    
                    // Subtle gradient overlay for depth
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
                    
                    // Border on the trailing edge
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
    
    private var canCloseDrawer: Bool {
        // Can only close drawer if an operator is selected
        return viewModel.selectedOperator != nil
    }
    
    // MARK: - Gestures
    
    /// Edge pan gesture to open the drawer from the leading edge
    private var edgePanGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Only open if dragging to the right from the leading edge
                if value.translation.width > 10 {
                    viewModel.openDrawer()
                }
            }
    }
    
    /// Drag gesture on the drawer itself to close it
    private var drawerDragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                // Only allow dragging to the left (closing) if an operator is selected
                if canCloseDrawer && value.translation.width < 0 {
                    state = value.translation.width
                }
            }
            .onEnded { value in
                // Only close if an operator is selected
                if canCloseDrawer {
                    // Close drawer if dragged more than 50% to the left
                    if value.translation.width < -drawerWidth * 0.5 {
                        viewModel.closeDrawer()
                    } else if value.translation.width < 0 {
                        // Snap back if not dragged far enough
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            // Drawer stays open
                        }
                    }
                }
            }
    }
}

#Preview {
    OperatorDrawer(viewModel: OperatorDrawerViewModel()) {
        NavigationStack {
            VStack {
                Text("Main Content")
                    .font(.title)
            }
            .navigationTitle("Preview")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        }
    }
    .modelContainer(for: Operator.self, inMemory: true)
}

