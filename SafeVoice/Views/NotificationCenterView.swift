//
//  NotificationCenterView.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI

// Notification center view
struct NotificationCenterView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var reportStore: ReportStore
    @State private var showingSettings = false
    
    var body: some View {
        List {
            if notificationManager.pendingNotifications.isEmpty && notificationManager.readNotifications.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No Notifications")
                                .font(.headline)
                            
                            Text("When you receive updates or alerts, they'll appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 40)
                }
            } else {
                // Unread notifications
                if !notificationManager.pendingNotifications.isEmpty {
                    Section(header: Text("New")) {
                        ForEach(notificationManager.pendingNotifications) { notification in
                            NotificationRow(notification: notification, reportStore: reportStore)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    notificationManager.markAsRead(id: notification.id)
                                    handleNotificationTap(notification)
                                }
                                .listRowBackground(Color.blue.opacity(0.1))
                        }
                    }
                }
                
                // Read notifications
                if !notificationManager.readNotifications.isEmpty {
                    Section(header: Text("Earlier")) {
                        ForEach(notificationManager.readNotifications.sorted(by: { $0.createdAt > $1.createdAt }).prefix(10)) { notification in
                            NotificationRow(notification: notification, reportStore: reportStore)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleNotificationTap(notification)
                                }
                                .listRowBackground(Color(.systemBackground))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NotificationSettingsView()
        }
        .onAppear {
            notificationManager.resetBadgeCount()
        }
    }
    
    // Handle tapping on a notification
    private func handleNotificationTap(_ notification: AppNotification) {
        switch notification.type {
        case .reportUpdate, .actionRequired:
            if let reportID = notification.referenceID,
               let report = reportStore.getReport(id: reportID) {
                // Would navigate to report detail in real implementation
                print("Navigate to report: \(report.id)")
            }
        case .draftReminder:
            if let reportID = notification.referenceID,
               let report = reportStore.getReport(id: reportID) {
                // Would navigate to draft editing in real implementation
                print("Navigate to edit draft: \(report.id)")
            }
        case .checkIn:
            // Would show check-in dialog in real implementation
            print("Show check-in dialog")
        case .appUpdate:
            // Would show app update info in real implementation
            print("Show app update info")
        case .securityAlert:
            // Would show security alert in real implementation
            print("Show security alert")
        }
    }
}

// Notification row component
struct NotificationRow: View {
    let notification: AppNotification
    let reportStore: ReportStore
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon
            Image(systemName: iconForNotificationType(notification.type))
                .font(.title2)
                .foregroundColor(colorForNotificationType(notification.type))
                .frame(width: 32, height: 32)
                .background(colorForNotificationType(notification.type).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let reportID = notification.referenceID,
                   let report = reportStore.getReport(id: reportID) {
                    Text("Report: \(report.reportType.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(timeAgoString(from: notification.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Icon for notification type
    private func iconForNotificationType(_ type: AppNotification.NotificationType) -> String {
        switch type {
        case .reportUpdate: return "bell.fill"
        case .draftReminder: return "doc.text.fill"
        case .checkIn: return "hand.wave.fill"
        case .actionRequired: return "exclamationmark.bubble.fill"
        case .appUpdate: return "arrow.up.circle.fill"
        case .securityAlert: return "lock.shield.fill"
        }
    }
    
    // Color for notification type
    private func colorForNotificationType(_ type: AppNotification.NotificationType) -> Color {
        switch type {
        case .reportUpdate: return .blue
        case .draftReminder: return .orange
        case .checkIn: return .green
        case .actionRequired: return .red
        case .appUpdate: return .purple
        case .securityAlert: return .red
        }
    }
    
    // Format date as time ago
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Notification settings view
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var allowNotifications = false
    @State private var disguiseNotifications = false
    @State private var showStatusUpdates = true
    @State private var showDraftReminders = true
    @State private var showCheckIns = true
    @State private var isRequestingPermission = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Access")) {
                    HStack {
                        Text("Allow Notifications")
                        Spacer()
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Toggle("", isOn: $allowNotifications)
                                .onChange(of: allowNotifications) { newValue in
                                    if newValue && !notificationManager.isAuthorized {
                                        requestNotificationPermission()
                                    }
                                }
                        }
                    }
                    
                    if notificationManager.isAuthorized {
                        Text("Notifications are enabled for SafeVoice")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Enable notifications to receive updates about your reports")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if notificationManager.isAuthorized {
                    Section(header: Text("Notification Types")) {
                        Toggle("Report Status Updates", isOn: $showStatusUpdates)
                            .onChange(of: showStatusUpdates) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "showStatusUpdates")
                            }
                        
                        Toggle("Draft Reminders", isOn: $showDraftReminders)
                            .onChange(of: showDraftReminders) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "showDraftReminders")
                            }
                        
                        Toggle("Wellbeing Check-ins", isOn: $showCheckIns)
                            .onChange(of: $showCheckIns.wrappedValue) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "showCheckIns")
                            }
                    }
                    
                    Section(header: Text("Privacy")) {
                        Toggle("Disguise Notifications", isOn: $disguiseNotifications)
                            .onChange(of: disguiseNotifications) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "disguiseNotifications")
                            }
                        
                        Text("When enabled, notifications will appear as \"Calendar Reminders\" instead of showing sensitive content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        Button(action: {
                            notificationManager.clearAllNotifications()
                        }) {
                            HStack {
                                Spacer()
                                Text("Clear All Notifications")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .onAppear {
                allowNotifications = notificationManager.isAuthorized
                disguiseNotifications = UserDefaults.standard.bool(forKey: "disguiseNotifications")
                showStatusUpdates = UserDefaults.standard.bool(forKey: "showStatusUpdates")
                showDraftReminders = UserDefaults.standard.bool(forKey: "showDraftReminders")
                showCheckIns = UserDefaults.standard.bool(forKey: "showCheckIns")
                
                // Set defaults if not set
                if !UserDefaults.standard.contains(key: "showStatusUpdates") {
                    UserDefaults.standard.set(true, forKey: "showStatusUpdates")
                    showStatusUpdates = true
                }
                if !UserDefaults.standard.contains(key: "showDraftReminders") {
                    UserDefaults.standard.set(true, forKey: "showDraftReminders")
                    showDraftReminders = true
                }
                if !UserDefaults.standard.contains(key: "showCheckIns") {
                    UserDefaults.standard.set(true, forKey: "showCheckIns")
                    showCheckIns = true
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    // Helper to request notification permission
    private func requestNotificationPermission() {
        isRequestingPermission = true
        notificationManager.requestAuthorization { granted in
            allowNotifications = granted
            isRequestingPermission = false
        }
    }
}
