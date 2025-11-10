//
//  ErrorStateView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable error state component for displaying errors with retry functionality.
struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.cyanAccent)
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .adaptiveGlassmorphismCard()
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorStateView(
            title: "Failed to load parking rights",
            message: "Network error occurred. Please check your connection and try again."
        ) {
            // Retry action
        }
        
        ErrorStateView(
            title: "Failed to load zones",
            message: "Unable to fetch zones from the API. Please try again later."
        ) {
            // Retry action
        }
    }
    .adaptiveGlassmorphismBackground()
}

