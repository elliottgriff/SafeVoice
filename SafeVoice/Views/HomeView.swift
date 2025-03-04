//
//  HomeView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reportStore: ReportStore
    @State private var showingNewReport = false
    @State private var showingAllReports = false
    @State private var showingTip = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                welcomeSection
                
                
                quickReportButton
                
                
                if !reportStore.activeReports.isEmpty {
                    activeReportsSection
                }
                
                
                if !reportStore.draftReports.isEmpty {
                    draftReportsSection
                }
                
                
                resourcesSection
                
                
                if showingTip {
                    safetyTipSection
                }
            }
            .padding()
        }
        .navigationTitle("SafeVoice")
        .sheet(isPresented: $showingNewReport) {
            NavigationView {
                ReportCreationView()
            }
        }
        .sheet(isPresented: $showingAllReports) {
            NavigationView {
                AllReportsView(reports: reportStore.activeReports)
            }
        }
    }
    
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome to SafeVoice")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your safe space to report concerns and get help.")
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 10)
    }
    
    
    private var quickReportButton: some View {
        Button(action: {
            showingNewReport = true
        }) {
            HStack {
                Image(systemName: "exclamationmark.bubble.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Create New Report")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
    }

    
    private var activeReportsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Your Reports")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    showingAllReports = true
                }
                .font(.callout)
                .foregroundColor(.blue)
            }
            
            ForEach(reportStore.activeReports.prefix(2)) { report in
                ReportCard(report: report)
            }
        }
        .padding(.vertical, 10)
    }
    
    
    private var draftReportsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Saved Drafts")
                    .font(.headline)
                
                Spacer()
            }
            
            ForEach(reportStore.draftReports) { report in
                DraftReportCard(report: report)
            }
        }
        .padding(.vertical, 10)
    }
    
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Resources")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    NavigationLink(destination: EmergencyContactsView()) {
                        ResourceCard(title: "Emergency Contacts", icon: "phone.fill", color: .red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AbuseTypesView()) {
                        ResourceCard(title: "Types of Abuse", icon: "info.circle", color: .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: SafetyPlanView()) {
                        ResourceCard(title: "Safety Planning", icon: "shield.fill", color: .green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: YourRightsView()) {
                        ResourceCard(title: "Your Rights", icon: "person.fill.checkmark", color: .purple)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    
    private var safetyTipSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Safety Tip")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingTip = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text(randomTip.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                Text(randomTip.content)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.vertical, 10)
    }
    
    
    private var randomTip: (title: String, content: String) {
        let tips = [
            (title: "Using Quick Exit", content: "If you need to hide the app quickly, tap the X button in the top right corner or shake your device. This will immediately switch to disguise mode."),
            (title: "Your Privacy Matters", content: "You can report anonymously without sharing your name or any identifying information. Your safety and privacy are our top priorities."),
            (title: "Getting Help", content: "If you're in immediate danger, don't wait - call emergency services at 911 or use the Emergency Contacts section."),
            (title: "Trust Your Feelings", content: "If something doesn't feel right, it's okay to reach out for help. Your feelings are valid, and you deserve to be safe."),
            (title: "Sharing the App", content: "If you know someone else who might need help, you can tell them about this app. It might help them too.")
        ]
        return tips[Int.random(in: 0..<tips.count)]
    }
}


struct AllReportsView: View {
    let reports: [Report]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(reports.sorted(by: { $0.timestamp > $1.timestamp })) { report in
                NavigationLink(destination: ReportDetailView(report: report)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(report.reportType.displayName)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            StatusBadge(status: report.status)
                        }
                        
                        Text(report.content)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(report.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("All Reports")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
    
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


extension HomeView {
    // Generate mock reports for testing
    private func generateMockReports() {
        
        let activeReports = [
            Report(
                id: "1",
                timestamp: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                reportType: .physical,
                content: "I witnessed someone being physically hurt at school today. It happened during lunch break in the cafeteria.",
                status: .inProgress
            ),
            Report(
                id: "2",
                timestamp: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                reportType: .bullying,
                content: "There's a group of kids who keep threatening a younger student and taking their things.",
                status: .resolved
            )
        ]
        
        let draftReports = [
            Report(
                id: "3",
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                reportType: .emotional,
                content: "Someone at home keeps yelling and saying mean things...",
                status: .drafted
            )
        ]
        
        for report in activeReports {
            reportStore.submitReport(report) { _ in }
        }
        
        for report in draftReports {
            reportStore.saveDraft(report)
        }
    }
}
