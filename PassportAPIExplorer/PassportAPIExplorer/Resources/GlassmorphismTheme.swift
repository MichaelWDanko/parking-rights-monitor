//
//  GlassmorphismTheme.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/22/25.
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary navy blue base
    static let navyBlue = Color(red: 0.05, green: 0.15, blue: 0.25)
    static let navyBlueLight = Color(red: 0.08, green: 0.20, blue: 0.32)
    static let navyBlueDark = Color(red: 0.03, green: 0.10, blue: 0.18)
    
    // Cyan accents
    static let cyanAccent = Color(red: 0.0, green: 0.8, blue: 1.0)
    static let cyanAccentLight = Color(red: 0.2, green: 0.9, blue: 1.0)
    static let cyanAccentDark = Color(red: 0.0, green: 0.6, blue: 0.8)
    
    // Glassmorphism backgrounds
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBackgroundLight = Color.white.opacity(0.15)
    static let glassBackgroundDark = Color.white.opacity(0.05)
    
    // Text colors for contrast
    static let glassTextPrimary = Color.white
    static let glassTextSecondary = Color.white.opacity(0.8)
    static let glassTextTertiary = Color.white.opacity(0.6)
}

// MARK: - Glassmorphism View Modifiers
struct GlassmorphismCard: ViewModifier {
    let intensity: Double
    let cornerRadius: CGFloat
    
    init(intensity: Double = 0.1, cornerRadius: CGFloat = 16) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
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

struct GlassmorphismBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        Color.navyBlue,
                        Color.navyBlue.opacity(0.95),
                        Color.navyBlue
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

struct GlassmorphismButton: ViewModifier {
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func body(content: Content) -> some View {
        content
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

struct GlassmorphismTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(.glassTextPrimary)
    }
}

struct GlassmorphismListRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .shadow(color: Color.cyanAccent.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphismCard(intensity: Double = 0.1, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassmorphismCard(intensity: intensity, cornerRadius: cornerRadius))
    }
    
    func glassmorphismBackground() -> some View {
        modifier(GlassmorphismBackground())
    }
    
    func glassmorphismButton(isPrimary: Bool = true) -> some View {
        modifier(GlassmorphismButton(isPrimary: isPrimary))
    }
    
    func glassmorphismTextField() -> some View {
        modifier(GlassmorphismTextField())
    }
    
    func glassmorphismListRow() -> some View {
        modifier(GlassmorphismListRow())
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
            .glassmorphismButton(isPrimary: isPrimary)
    }
}

// MARK: - Custom Navigation Styles
struct GlassmorphismNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

extension View {
    func glassmorphismNavigation() -> some View {
        modifier(GlassmorphismNavigationStyle())
    }
}

// MARK: - Custom Tab View Style
struct GlassmorphismTabViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.navyBlue.opacity(0.9))
            .preferredColorScheme(.dark)
    }
}

extension View {
    func glassmorphismTabView() -> some View {
        modifier(GlassmorphismTabViewStyle())
    }
}
