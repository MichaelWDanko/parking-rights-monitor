//
//  iCloudStatusCard.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/30/25.
//

import SwiftUI

/// Card component displaying iCloud sync status and controls.
struct iCloudStatusCard: View {
    let accountStatus: String
    let cloudKitAvailable: Bool
    let diagnosticMessage: String
    let lastSyncTime: Date?
    let isSyncing: Bool
    let onSync: () -> Void
    let onCheckStatus: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("iCloud Status")
                .font(.headline)
                .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
            
            HStack(spacing: 12) {
                Image(systemName: cloudKitAvailable ? "icloud.fill" : "icloud.slash.fill")
                    .foregroundColor(cloudKitAvailable ? Color.adaptiveCyanAccent(colorScheme == .dark) : .red)
                    .font(.title2)
                    .symbolEffect(.pulse)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(accountStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextPrimary(colorScheme == .dark))
                    
                    if let lastSync = lastSyncTime {
                        Text("Last sync: \(lastSync.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    }
                }
                
                Spacer()
                
                Image(systemName: cloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(cloudKitAvailable ? .green : .red)
            }
            
            // Diagnostic Information
            if !diagnosticMessage.isEmpty {
                Text(diagnosticMessage)
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme == .dark))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.adaptiveGlassBackground(colorScheme == .dark).opacity(0.5))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                Button(action: onSync) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                        Text(isSyncing ? "Syncing..." : "Sync Now")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: true))
                .disabled(isSyncing || !cloudKitAvailable)
                
                Button(action: onCheckStatus) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("Check iCloud Status")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                }
                .buttonStyle(GlassmorphismButtonStyle(isPrimary: false))
            }
        }
        .padding()
        .adaptiveGlassmorphismCard()
    }
}

#Preview {
    VStack(spacing: 20) {
        iCloudStatusCard(
            accountStatus: "iCloud Account: Available",
            cloudKitAvailable: true,
            diagnosticMessage: "✅ iCloud is properly configured. CloudKit sync is active.",
            lastSyncTime: Date(),
            isSyncing: false,
            onSync: {},
            onCheckStatus: {}
        )
        
        iCloudStatusCard(
            accountStatus: "iCloud Account: Not Signed In",
            cloudKitAvailable: false,
            diagnosticMessage: "⚠️ No iCloud account signed in.",
            lastSyncTime: nil,
            isSyncing: false,
            onSync: {},
            onCheckStatus: {}
        )
    }
    .padding()
    .adaptiveGlassmorphismBackground()
}

