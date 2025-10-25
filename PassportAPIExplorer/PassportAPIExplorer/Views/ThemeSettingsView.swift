//
//  ThemeSettingsView.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("selectedThemeMode") private var selectedThemeMode: ThemeMode = .auto
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Theme Preview Section
                VStack(spacing: 16) {
                    Text("Theme Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    // Preview cards showing current theme
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample Card")
                                    .font(.headline)
                                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                Text("This shows how content will look")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                            }
                            Spacer()
                            Text("Preview")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cyanAccent)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .adaptiveGlassmorphismCard()
                    }
                }
                .padding()
                .adaptiveGlassmorphismCard()
                .padding(.horizontal)
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose Theme")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    VStack(spacing: 8) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Button(action: {
                                selectedThemeMode = mode
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.displayName)
                                            .font(.headline)
                                            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                                        
                                        Text(themeDescription(for: mode))
                                            .font(.caption)
                                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedThemeMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.cyanAccent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .adaptiveGlassmorphismCard()
                        }
                    }
                }
                .padding()
                .adaptiveGlassmorphismCard()
                .padding(.horizontal)
                
                Spacer()
            }
            .adaptiveGlassmorphismBackground()
            .navigationTitle("Theme Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                }
            }
        }
    }
    
    private func themeDescription(for mode: ThemeMode) -> String {
        switch mode {
        case .auto:
            return "Follows system appearance"
        case .light:
            return "Light glassmorphism theme"
        case .dark:
            return "Dark glassmorphism theme"
        }
    }
}

#Preview {
    ThemeSettingsView()
}
