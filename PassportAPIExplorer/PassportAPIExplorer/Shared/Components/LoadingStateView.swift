//
//  LoadingStateView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable loading state component for displaying loading indicators.
struct LoadingStateView: View {
    let message: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ProgressView(message)
            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(message: "Loading parking rights...")
        LoadingStateView(message: "Loading zones...")
        LoadingStateView(message: "Initializing...")
    }
    .adaptiveGlassmorphismBackground()
}

