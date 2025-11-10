//
//  EmptyStateView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable empty state component for displaying when there's no data to show.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        if secondaryActionTitle != nil {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
            }
            
            if secondaryActionTitle != nil, let secondaryAction = secondaryAction {
                Button(action: secondaryAction) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: false))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .adaptiveGlassmorphismCard()
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "car",
            title: "No parking rights available",
            message: "This zone doesn't have any active parking rights"
        )
        
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No zones found",
            message: "Try adjusting your search terms",
            actionTitle: "Clear Search",
            action: {
                // Action
            }
        )
        
        EmptyStateView(
            icon: "location.slash",
            title: "No zones available",
            message: "This operator doesn't have any zones configured",
            actionTitle: "Refresh",
            action: {
                // Primary action
            },
            secondaryActionTitle: "Search",
            secondaryAction: {}
        )
    }
    .adaptiveGlassmorphismBackground()
}

