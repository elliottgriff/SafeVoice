//
//  WelcomeBackView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI
import Combine

// Welcome back view for returning users
struct WelcomeBackView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reportStore: ReportStore
    
    var body: some View {
        VStack(spacing: 25) {
            // Welcome header
            VStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Welcome Back!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let user = appState.currentUser, let name = user.displayName {
                    Text("Good to see you again, \(name)")
                        .font(.title3)
                } else {
                    Text("Good to see you again")
                        .font(.title3)
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Report updates
            if !reportStore.activeReports.isEmpty {
                reportUpdatesView
            }
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: {
                    appState.showingNewReport = true
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Create New Report")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue to App")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // Reports update view
    private var reportUpdatesView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Report Updates")
                .font(.headline)
            
            ForEach(reportStore.activeReports.filter { $0.status != .drafted }.prefix(2)) { report in
                HStack {
                    Image(systemName: statusIcon(for: report))
                        .foregroundColor(statusColor(for: report))
                        .font(.headline)
                        .frame(width: 30, height: 30)
                        .background(statusColor(for: report).opacity(0.1))
                        .cornerRadius(15)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.reportType.displayName)
                            .fontWeight(.medium)
                        
                        Text("Status: \(report.status.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        appState.selectedReportID = report.id
                        dismiss()
                    }) {
                        Text("View")
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Helper for status icon
    private func statusIcon(for report: Report) -> String {
        switch report.status {
        case .drafted: return "doc.fill"
        case .submitted: return "paperplane.fill"
        case .received: return "envelope.open.fill"
        case .inProgress: return "person.fill.checkmark"
        case .resolved: return "checkmark.seal.fill"
        }
    }
    
    // Helper for status color
    private func statusColor(for report: Report) -> Color {
        switch report.status {
        case .drafted: return .gray
        case .submitted: return .orange
        case .received: return .blue
        case .inProgress: return .purple
        case .resolved: return .green
        }
    }
}
