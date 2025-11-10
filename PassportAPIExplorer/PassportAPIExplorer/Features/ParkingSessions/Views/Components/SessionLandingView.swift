//
//  SessionLandingView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Landing page view shown when there are no parking sessions.
/// Displays an empty state with a call-to-action to start a new session.
struct SessionLandingView: View {
    let onStartNewSession: () -> Void
    let onRefresh: () async -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Icon with pulsing gradient
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyanAccent, Color.cyanAccentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                    
                    VStack(spacing: 8) {
                        Text("No Parking Sessions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                        
                        Text("Start a new parking session to begin tracking")
                            .font(.subheadline)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Primary CTA Button
                Button(action: onStartNewSession) {
                    Label("Start New Session", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 500)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

#Preview {
    SessionLandingView(
        onStartNewSession: {},
        onRefresh: { 
            try? await Task.sleep(nanoseconds: 1_000_000_000) 
        }
    )
    .adaptiveGlassmorphismBackground()
}

