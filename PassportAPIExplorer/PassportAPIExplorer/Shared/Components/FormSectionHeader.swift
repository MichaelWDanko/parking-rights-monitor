//
//  FormSectionHeader.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable form section header component for consistent styling across forms.
struct FormSectionHeader: View {
    let title: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(title)
            .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
    }
}

#Preview {
    Form {
        Section(header: FormSectionHeader(title: "Operator")) {
            Text("Content")
        }
        
        Section(header: FormSectionHeader(title: "Zone")) {
            Text("Content")
        }
        
        Section(header: FormSectionHeader(title: "Vehicle")) {
            Text("Content")
        }
    }
    .adaptiveGlassmorphismBackground()
}

