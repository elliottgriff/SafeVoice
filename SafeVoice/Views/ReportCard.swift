//
//  ReportCard.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI

// Report card component
struct ReportCard: View {
    let report: Report
    
    var body: some View {
        NavigationLink(destination: ReportDetailView(report: report)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: iconForReportType(report.reportType))
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(width: 30, height: 30)
                        .background(colorForReportType(report.reportType))
                        .cornerRadius(8)
                    
                    Text(report.reportType.displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    StatusBadge(status: report.status)
                }
                
                Text(report.content)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(formatDate(report.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if report.isAnonymous {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.slash")
                                .font(.caption)
                            Text("Anonymous")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to get icon for report type
    private func iconForReportType(_ type: Report.ReportType) -> String {
        switch type {
        case .physical: return "hand.raised.slash.fill"
        case .emotional: return "heart.slash.fill"
        case .neglect: return "xmark.circle.fill"
        case .sexual: return "exclamationmark.shield.fill"
        case .bullying: return "person.2.slash.fill"
        case .other: return "exclamationmark.triangle.fill"
        }
    }
    
    // Helper to get color for report type
    private func colorForReportType(_ type: Report.ReportType) -> Color {
        switch type {
        case .physical: return .red
        case .emotional: return .purple
        case .neglect: return .blue
        case .sexual: return .orange
        case .bullying: return .green
        case .other: return .gray
        }
    }
}

// Status badge component
struct StatusBadge: View {
    let status: Report.ReportStatus
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var statusText: String {
        switch status {
        case .drafted: return "Draft"
        case .submitted: return "Submitted"
        case .received: return "Received"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .drafted: return .gray
        case .submitted: return .orange
        case .received: return .blue
        case .inProgress: return .purple
        case .resolved: return .green
        }
    }
}

// Draft report card component
struct DraftReportCard: View {
    let report: Report
    @EnvironmentObject var reportStore: ReportStore
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: {
            showingEditSheet = true
        }) {
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: "doc.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.content.isEmpty ? "Empty draft" : report.content)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(formatDate(report.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Delete draft
                    reportStore.deleteReport(id: report.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ReportCreationView(report: report, isEditingDraft: true)
            }
        }
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Resource card component
struct ResourceCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Report detail view
struct ReportDetailView: View {
    let report: Report
    @EnvironmentObject var reportStore: ReportStore
    @State private var showingDeleteConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Report header
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(titleForReportType(report.reportType))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(formatDate(report.timestamp))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: report.status)
                }
                
                Divider()
                
                // Report content
                VStack(alignment: .leading, spacing: 15) {
                    Text("Report Details")
                        .font(.headline)
                    
                    Text(report.content)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Media attachments if any
                if !report.mediaAttachments.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Attachments")
                            .font(.headline)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 15) {
                                ForEach(report.mediaAttachments) { attachment in
                                    mediaAttachmentView(for: attachment)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Status updates
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Status Updates")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Report ID: \(report.id.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if report.statusUpdates.isEmpty {
                        // Initial status
                        HStack {
                            Image(systemName: statusIcon(for: report.status))
                                .foregroundColor(statusColor(for: report.status))
                            
                            Text(statusMessage(for: report.status))
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(statusColor(for: report.status).opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        // Show status updates
                        ForEach(report.statusUpdates.sorted(by: { $0.timestamp > $1.timestamp })) { update in
                            StatusUpdateRow(update: update)
                        }
                    }
                }
                
                Divider()
                
                // Actions
                VStack(alignment: .leading, spacing: 15) {
                    Text("Actions")
                        .font(.headline)
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            
                            Text("Delete Report")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("Report Details", displayMode: .inline)
        .alert("Delete Report", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                reportStore.deleteReport(id: report.id)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this report? This action cannot be undone.")
        }
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to get title for report type
    private func titleForReportType(_ type: Report.ReportType) -> String {
        switch type {
        case .physical: return "Physical Abuse Report"
        case .emotional: return "Emotional Abuse Report"
        case .neglect: return "Neglect Report"
        case .sexual: return "Sexual Abuse Report"
        case .bullying: return "Bullying Report"
        case .other: return "Other Report"
        }
    }
    
    // Helper to get status icon
    private func statusIcon(for status: Report.ReportStatus) -> String {
        switch status {
        case .drafted: return "doc.fill"
        case .submitted: return "paperplane.fill"
        case .received: return "envelope.open.fill"
        case .inProgress: return "person.fill.checkmark"
        case .resolved: return "checkmark.seal.fill"
        }
    }
    
    // Helper to get status color
    private func statusColor(for status: Report.ReportStatus) -> Color {
        switch status {
        case .drafted: return .gray
        case .submitted: return .orange
        case .received: return .blue
        case .inProgress: return .purple
        case .resolved: return .green
        }
    }
    
    // Helper to get status message
    private func statusMessage(for status: Report.ReportStatus) -> String {
        switch status {
        case .drafted:
            return "This report is saved as a draft."
        case .submitted:
            return "Your report has been submitted and is awaiting review."
        case .received:
            return "Your report has been received and is under review."
        case .inProgress:
            return "Your report is now being handled by a case worker who will take appropriate action."
        case .resolved:
            return "Your report has been resolved. Thank you for helping make a difference."
        }
    }
    
    // Helper to render media attachment
    private func mediaAttachmentView(for attachment: MediaAttachment) -> some View {
        switch attachment.type {
        case .image:
            return AnyView(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .frame(width: 100, height: 100)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            )
        case .audio:
            return AnyView(
                Image(systemName: "waveform")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .frame(width: 100, height: 100)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            )
        case .video:
            return AnyView(
                Image(systemName: "video")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .frame(width: 100, height: 100)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            )
        case .document:
            return AnyView(
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .frame(width: 100, height: 100)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
            )
        }
    }
}

// Status update row
struct StatusUpdateRow: View {
    let update: StatusUpdate
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Status icon
            Image(systemName: iconForStatus(update.newStatus))
                .foregroundColor(colorForStatus(update.newStatus))
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(titleForStatus(update.newStatus))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatDate(update.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(update.message)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(colorForStatus(update.newStatus).opacity(0.1))
        .cornerRadius(10)
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to get icon for status
    private func iconForStatus(_ status: Report.ReportStatus) -> String {
        switch status {
        case .drafted: return "doc.fill"
        case .submitted: return "paperplane.fill"
        case .received: return "envelope.open.fill"
        case .inProgress: return "person.fill.checkmark"
        case .resolved: return "checkmark.seal.fill"
        }
    }
    
    // Helper to get color for status
    private func colorForStatus(_ status: Report.ReportStatus) -> Color {
        switch status {
        case .drafted: return .gray
        case .submitted: return .orange
        case .received: return .blue
        case .inProgress: return .purple
        case .resolved: return .green
        }
    }
    
    // Helper to get title for status
    private func titleForStatus(_ status: Report.ReportStatus) -> String {
        switch status {
        case .drafted: return "Draft Saved"
        case .submitted: return "Report Submitted"
        case .received: return "Report Received"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }
}
