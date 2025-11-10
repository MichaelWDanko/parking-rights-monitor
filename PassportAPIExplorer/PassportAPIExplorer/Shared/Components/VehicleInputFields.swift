//
//  VehicleInputFields.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable vehicle input fields component for forms.
struct VehicleInputFields: View {
    @Binding var vehiclePlate: String
    @Binding var vehicleState: String
    @Binding var vehicleCountry: String
    @Binding var spaceNumber: String
    var showRandomButton: Bool = true
    var onRandomGenerate: (() -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section {
            if showRandomButton {
                HStack {
                    Text("Vehicle")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    Spacer()
                    if let onRandomGenerate = onRandomGenerate {
                        Button(action: onRandomGenerate) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Random")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.small)
                    }
                }
            }
            
            TextField("License Plate", text: $vehiclePlate, prompt: Text("ABC1234"))
                .autocapitalization(.allCharacters)
            
            HStack {
                TextField("State Code", text: $vehicleState, prompt: Text("CA"))
                    .autocapitalization(.allCharacters)
                
                TextField("Country Code", text: $vehicleCountry, prompt: Text("US"))
                    .autocapitalization(.allCharacters)
            }
            
            TextField("Space Number (Optional)", text: $spaceNumber, prompt: Text("1-50"))
        }
        .listRowBackground(Color.glassBackground)
    }
}

#Preview {
    Form {
        VehicleInputFields(
            vehiclePlate: .constant("ABC1234"),
            vehicleState: .constant("CA"),
            vehicleCountry: .constant("US"),
            spaceNumber: .constant(""),
            onRandomGenerate: {}
        )
    }
    .adaptiveGlassmorphismBackground()
}

