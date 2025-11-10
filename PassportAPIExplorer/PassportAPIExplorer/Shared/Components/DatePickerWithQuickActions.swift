//
//  DatePickerWithQuickActions.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Reusable date picker component with quick duration action buttons.
struct DatePickerWithQuickActions: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    var onQuickDuration: ((TimeInterval) -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: FormSectionHeader(title: "Session Times")) {
            DatePicker("Start Time", selection: $startTime)
            
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("End Time", selection: $endTime)
                
                if let onQuickDuration = onQuickDuration {
                    HStack(spacing: 8) {
                        Text("Quick Duration:")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                        
                        Button("30m") {
                            onQuickDuration(1800)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.mini)
                        
                        Button("1h") {
                            onQuickDuration(3600)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.mini)
                        
                        Button("2h") {
                            onQuickDuration(7200)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.mini)
                        
                        Button("4h") {
                            onQuickDuration(14400)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.mini)
                        
                        Button("8h") {
                            onQuickDuration(28800)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.adaptiveCyanAccent(colorScheme == .dark))
                        .controlSize(.mini)
                    }
                }
            }
        }
        .listRowBackground(Color.glassBackground)
    }
}

#Preview {
    Form {
        DatePickerWithQuickActions(
            startTime: .constant(Date()),
            endTime: .constant(Date().addingTimeInterval(3600))
        ) { duration in
            print("Set duration: \(duration)")
        }
    }
    .adaptiveGlassmorphismBackground()
}

