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
    
    @State private var isEdgePanning: Bool = false
    @State private var edgePanTracking: CGFloat = 0
    
    @State private var isInteracting: Bool = false
    @State private var interactiveOffset: CGFloat = 0 // 0 = open, -drawerWidth = closed
    
    @State private var isDrawerDragging: Bool = false
    @State private var drawerDragTracking: CGFloat = 0
    
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
                .disabled(viewModel.isDrawerOpen || isEdgePanning || isInteracting)
            
            // Dimming overlay
            if viewModel.isDrawerOpen || isEdgePanning || isInteracting {
                Color.black
                    .opacity(dimmingOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Only allow closing if an operator is selected
                        if viewModel.selectedOperator != nil {
                            viewModel.closeDrawer()
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: dimmingOpacity)
            }
            
            // Drawer panel - always rendered but positioned offscreen when closed
            drawerPanel
                .offset(x: drawerOffset)
                .contentShape(Rectangle())
                .highPriorityGesture(drawerDragGesture)
            
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
    
    private var drawerOffset: CGFloat {
        // While interacting (edge pan or drawer drag), use the interactive offset in drawer coordinates
        if isInteracting {
            return interactiveOffset
        }

        // While actively panning from the edge (legacy support), use tracking
        if isEdgePanning {
            let clamped = min(max(edgePanTracking, 0), drawerWidth)
            return -drawerWidth + clamped
        }

        // Otherwise, snap to the state-driven position
        return viewModel.isDrawerOpen ? 0 : -drawerWidth
    }
    
    private var dimmingOpacity: Double {
        if viewModel.isDrawerOpen && !isInteracting && !isEdgePanning {
            return 0.3
        }

        // Compute openness fraction from interactive offset when interacting or edge panning
        if isInteracting {
            let openFraction = 1 - min(max((-interactiveOffset) / drawerWidth, 0), 1) // 0 closed, 1 open
            return 0.3 * openFraction
        } else if isEdgePanning {
            let fraction = min(max(edgePanTracking / drawerWidth, 0), 1)
            return 0.3 * fraction
        }

        return 0.0
    }
    
    // MARK: - Gestures
    
    /// Edge pan gesture to open the drawer from the leading edge
    private var edgePanGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if value.translation.width > 0 {
                    isEdgePanning = true
                    isInteracting = true
                    let clamped = min(value.translation.width, drawerWidth)
                    interactiveOffset = -drawerWidth + clamped
                    edgePanTracking = clamped
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let vx = value.velocity.width // points per second

                let openByDistance = dx > drawerWidth * 0.4
                let openByVelocity = vx > 800

                if openByDistance || openByVelocity {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.openDrawer()
                        interactiveOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        // keep closed
                        viewModel.closeDrawer()
                        interactiveOffset = -drawerWidth
                    }
                }

                // Clear tracking after committing state
                isEdgePanning = false
                edgePanTracking = 0
                isInteracting = false
            }
    }
    
    /// Drag gesture on the drawer itself to close it
    private var drawerDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow dragging to the left (closing) if an operator is selected
                if canCloseDrawer && value.translation.width < 0 {
                    isDrawerDragging = true
                    isInteracting = true
                    let clamped = max(value.translation.width, -drawerWidth)
                    drawerDragTracking = clamped
                    // Base is 0 when open; apply clamped negative translation
                    interactiveOffset = 0 + clamped
                }
            }
            .onEnded { value in
                // Only close if an operator is selected
                if canCloseDrawer {
                    let dx = value.translation.width
                    let vx = value.velocity.width // points per second

                    let closeByDistance = dx < -drawerWidth * 0.4
                    let closeByVelocity = vx < -800

                    if closeByDistance || closeByVelocity {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.closeDrawer()
                            interactiveOffset = -drawerWidth
                        }
                    } else if dx < 0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            // Snap back open
                            viewModel.openDrawer()
                            interactiveOffset = 0
                        }
                    }
                }
                // Clear tracking after committing state
                isDrawerDragging = false
                drawerDragTracking = 0
                isInteracting = false
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

