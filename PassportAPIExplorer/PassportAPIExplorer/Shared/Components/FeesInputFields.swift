//
//  FeesInputFields.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable fees input fields component for forms.
struct FeesInputFields: View {
    @Binding var parkingFee: String
    @Binding var convenienceFee: String
    @Binding var tax: String
    @Binding var currencyCode: String
    var showRandomButton: Bool = false
    var onRandomGenerate: (() -> Void)? = nil
    var showCurrencyCode: Bool = true
    var showHeader: Bool = true
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: showHeader ? FormSectionHeader(title: "Event Fees") : nil) {
            if showRandomButton {
                HStack {
                    Text("Event Fees")
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
            
            HStack {
                Text("Parking")
                Spacer()
                TextField("0.00", text: $parkingFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Convenience")
                Spacer()
                TextField("0.00", text: $convenienceFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                TextField("0.00", text: $tax)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            if showCurrencyCode {
                HStack {
                    Text("Currency Code")
                    Spacer()
                    TextField("USD", text: $currencyCode)
                        .autocapitalization(.allCharacters)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
        }
        .listRowBackground(Color.glassBackground)
    }
}

/// Reusable total fees input fields component for extend/stop forms.
struct TotalFeesInputFields: View {
    @Binding var totalParkingFee: String
    @Binding var totalConvenienceFee: String
    @Binding var totalTax: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: FormSectionHeader(title: "Total Session Fees")) {
            HStack {
                Text("Parking")
                Spacer()
                TextField("0.00", text: $totalParkingFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Convenience")
                Spacer()
                TextField("0.00", text: $totalConvenienceFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Tax")
                Spacer()
                TextField("0.00", text: $totalTax)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .listRowBackground(Color.glassBackground)
    }
}

#Preview {
    Form {
        FeesInputFields(
            parkingFee: .constant("1.25"),
            convenienceFee: .constant("0.25"),
            tax: .constant("0.10"),
            currencyCode: .constant("USD"),
            showRandomButton: true,
            onRandomGenerate: {}
        )
        
        TotalFeesInputFields(
            totalParkingFee: .constant("2.50"),
            totalConvenienceFee: .constant("0.50"),
            totalTax: .constant("0.20")
        )
    }
    .adaptiveGlassmorphismBackground()
}

