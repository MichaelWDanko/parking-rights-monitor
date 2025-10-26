//
//  GlassmorphismTheme.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Environment Key for Theme Updates
private struct ThemeUpdateKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var themeUpdateTrigger: Bool {
        get { self[ThemeUpdateKey.self] }
        set { self[ThemeUpdateKey.self] = newValue }
    }
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"
    
    var displayName: String {
        return self.rawValue
    }
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:
            return nil // Let system handle it automatically
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Adaptive Color Palette
extension Color {
    // Dark Mode Colors
    static let navyBlue = Color(red: 0.05, green: 0.15, blue: 0.25)
    static let navyBlueLight = Color(red: 0.08, green: 0.20, blue: 0.32)
    static let navyBlueDark = Color(red: 0.03, green: 0.10, blue: 0.18)
    
    // Light Mode Colors
    static let lightBlue = Color(red: 0.9, green: 0.95, blue: 1.0)
    static let lightBlueLight = Color(red: 0.95, green: 0.98, blue: 1.0)
    static let lightBlueDark = Color(red: 0.85, green: 0.92, blue: 0.98)
    
    // Cyan accents (work in both modes)
    static let cyanAccent = Color(red: 0.0, green: 0.8, blue: 1.0)
    static let cyanAccentLight = Color(red: 0.2, green: 0.9, blue: 1.0)
    static let cyanAccentDark = Color(red: 0.0, green: 0.6, blue: 0.8)
    
    // Adaptive colors
    static func adaptiveBackground(_ isDark: Bool) -> Color {
        return isDark ? navyBlue : lightBlue
    }
    
    static func adaptiveBackgroundLight(_ isDark: Bool) -> Color {
        return isDark ? navyBlueLight : lightBlueLight
    }
    
    static func adaptiveBackgroundDark(_ isDark: Bool) -> Color {
        return isDark ? navyBlueDark : lightBlueDark
    }
    
    static func adaptiveGlassBackground(_ isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.8)
    }
    
    static func adaptiveGlassBackgroundLight(_ isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.15) : Color.white.opacity(0.9)
    }
    
    static func adaptiveGlassBackgroundDark(_ isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }
    
    static func adaptiveTextPrimary(_ isDark: Bool) -> Color {
        return isDark ? Color.white : Color.black
    }
    
    static func adaptiveTextSecondary(_ isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.8) : Color.black.opacity(0.7)
    }
    
    static func adaptiveTextTertiary(_ isDark: Bool) -> Color {
        return isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)
    }
    
    // Legacy static colors for backward compatibility
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBackgroundLight = Color.white.opacity(0.15)
    static let glassBackgroundDark = Color.white.opacity(0.05)
    static let glassTextPrimary = Color.white
    static let glassTextSecondary = Color.white.opacity(0.8)
    static let glassTextTertiary = Color.white.opacity(0.6)
}

// MARK: - Adaptive Glassmorphism View Modifiers
struct AdaptiveGlassmorphismCard: ViewModifier {
    let intensity: Double
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    init(intensity: Double = 0.1, cornerRadius: CGFloat = 16) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.adaptiveGlassBackground(isDark))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.2 : 0.1),
                                        Color.white.opacity(isDark ? 0.05 : 0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .shadow(color: Color.cyanAccent.opacity(0.1), radius: 20, x: 0, y: 10)
            )
    }
}

// MARK: - Legacy Glassmorphism View Modifiers (for backward compatibility)

struct AdaptiveGlassmorphismBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .background(
                LinearGradient(
                    colors: [
                        Color.adaptiveBackground(isDark),
                        Color.adaptiveBackgroundLight(isDark),
                        Color.adaptiveBackground(isDark)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}





// MARK: - View Extensions

extension View {
    
    func adaptiveGlassmorphismCard(intensity: Double = 0.1, cornerRadius: CGFloat = 16) -> some View {
        modifier(AdaptiveGlassmorphismCard(intensity: intensity, cornerRadius: cornerRadius))
    }
    
    
    
    
}

// MARK: - Custom Button Styles
struct GlassmorphismButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .foregroundColor(isPrimary ? .navyBlue : .glassTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isPrimary ? 
                        LinearGradient(
                            colors: [Color.cyanAccent, Color.cyanAccentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.glassBackground, Color.glassBackgroundLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.cyanAccent.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Custom Navigation Styles


// MARK: - Adaptive Glassmorphism Navigation Style
struct AdaptiveGlassmorphismNavigationStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(isDark ? .dark : .light, for: .navigationBar)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [
                    .foregroundColor: isDark ? UIColor.white : UIColor.black
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: isDark ? UIColor.white : UIColor.black
                ]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

// MARK: - Adaptive Glassmorphism Text Field
struct AdaptiveGlassmorphismTextField: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveGlassBackground(isDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.2 : 0.1),
                                        Color.white.opacity(isDark ? 0.05 : 0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(Color.adaptiveTextPrimary(isDark))
    }
}

// MARK: - Adaptive Glassmorphism List Row
struct AdaptiveGlassmorphismListRow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.adaptiveGlassBackground(isDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.2 : 0.1),
                                        Color.white.opacity(isDark ? 0.05 : 0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
    }
}

extension View {
    
    func adaptiveGlassmorphismNavigation() -> some View {
        modifier(AdaptiveGlassmorphismNavigationStyle())
    }
    
    func adaptiveGlassmorphismBackground() -> some View {
        modifier(AdaptiveGlassmorphismBackground())
    }
    
    func adaptiveGlassmorphismCard() -> some View {
        modifier(AdaptiveGlassmorphismCard())
    }
    
    func adaptiveGlassmorphismTextField() -> some View {
        modifier(AdaptiveGlassmorphismTextField())
    }
    
    func adaptiveGlassmorphismListRow() -> some View {
        modifier(AdaptiveGlassmorphismListRow())
    }
    
    func adaptiveGlassmorphismTabView() -> some View {
        modifier(AdaptiveGlassmorphismTabViewStyle())
    }
}

// MARK: - Custom Tab View Style

// MARK: - Adaptive Tab View Style
struct AdaptiveGlassmorphismTabViewStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        content
            .background(Color.adaptiveBackground(isDark).opacity(0.9))
    }
}

extension View {
}
