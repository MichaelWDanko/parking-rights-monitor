//
//  DrawerHeader.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 11/10/25.
//

import SwiftUI

/// Header component for the operator drawer with safe area handling
struct DrawerHeader: View {
    let safeAreaTop: CGFloat
    let onAddOperator: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Safe area spacer for status bar and Dynamic Island
            Color.clear
                .frame(height: safeAreaTop)
            
            // Header content
            HStack {
                Text("Operators")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                
                Spacer()
                
                Button(action: onAddOperator) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.adaptiveCyanAccent(colorScheme == .dark))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Divider
            Divider()
                .background(Color.adaptiveTextSecondary(colorScheme == .dark).opacity(0.3))
                .padding(.horizontal, 20)
        }
    }
}

#Preview {
    DrawerHeader(safeAreaTop: 50, onAddOperator: {})
        .background(Color.navyBlue)
}

