//
//  NotificationManager.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import UserNotifications
import Combine
import UIKit

// Notification manager to handle app notifications
class NotificationManager: ObservableObject {
    // Singleton instance
    static let shared = NotificationManager()
    
    // Published properties
    @Published var isAuthorized = false
    @Published var pendingNotifications: [AppNotification] = []
    @Published var readNotifications: [AppNotification] = []
    
    // UserDefaults keys
    private enum Keys {
        static let pendingNotifications = "pendingNotifications"
        static let readNotifications = "readNotifications"
        static let lastCheckTime = "lastNotificationCheckTime"
    }
    
    private init() {
        loadSavedNotifications()
        checkAuthorizationStatus()
    }
    
    // Request permission for notifications
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    // Check current authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Schedule a notification
    func scheduleNotification(for notification: AppNotification) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        // Set disguised title if needed
        if notification.disguiseNotifications {
            content.title = "Calendar Reminder"
            content.body = "You have an upcoming reminder to check."
        } else {
            content.title = notification.title
            content.body = notification.body
        }
        
        content.sound = .default
        content.badge = NSNumber(value: self.pendingNotifications.count + 1)
        
        // Add user info for handling notification actions
        content.userInfo = [
            "id": notification.id,
            "type": notification.type.rawValue,
            "reference_id": notification.referenceID ?? ""
        ]
        
        // Create trigger based on notification timing
        let trigger: UNNotificationTrigger
        
        switch notification.timing {
        case .immediate:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        case .delayed(let seconds):
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        case .scheduled(let date):
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.pendingNotifications.append(notification)
                    self.saveNotifications()
                }
            }
        }
    }
    
    // Cancel a scheduled notification
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
        if let index = pendingNotifications.firstIndex(where: { $0.id == id }) {
            pendingNotifications.remove(at: index)
            saveNotifications()
        }
    }
    
    // Mark notification as read
    func markAsRead(id: String) {
        if let index = pendingNotifications.firstIndex(where: { $0.id == id }) {
            let notification = pendingNotifications.remove(at: index)
            notification.markAsRead()
            readNotifications.append(notification)
            saveNotifications()
            
            // Update badge count
            updateBadgeCount()
        }
    }
    
    // Update app badge count
    func updateBadgeCount() {
        if isAuthorized {
            UNUserNotificationCenter.current().setBadgeCount(pendingNotifications.count)
        }
    }
    
    // Reset badge count to zero
    func resetBadgeCount() {
        if isAuthorized {
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
    
    // Create a notification for a report status update
    func createReportStatusNotification(report: Report, update: StatusUpdate) -> AppNotification {
        let title: String
        let body: String
        
        switch update.newStatus {
        case .received:
            title = "Report Received"
            body = "Your report has been received and is under review."
        case .inProgress:
            title = "Report In Progress"
            body = "Your report is now being handled by a specialist."
        case .resolved:
            title = "Report Resolved"
            body = "Your report has been resolved. Thank you for your help."
        default:
            title = "Report Status Update"
            body = update.message
        }
        
        return AppNotification(
            id: UUID().uuidString,
            title: title,
            body: body,
            type: .reportUpdate,
            timing: .immediate,
            referenceID: report.id,
            disguiseNotifications: UserDefaults.standard.bool(forKey: "disguiseNotifications")
        )
    }
    
    // Create a notification reminding user of a draft report
    func createDraftReminderNotification(report: Report) -> AppNotification {
        return AppNotification(
            id: UUID().uuidString,
            title: "Complete Your Report",
            body: "You have a report draft waiting to be submitted.",
            type: .draftReminder,
            timing: .scheduled(Date().addingTimeInterval(86400)), // 24 hours from now
            referenceID: report.id,
            disguiseNotifications: UserDefaults.standard.bool(forKey: "disguiseNotifications")
        )
    }
    
    // Create a check-in notification
    func createCheckInNotification() -> AppNotification {
        return AppNotification(
            id: UUID().uuidString,
            title: "SafeVoice Check-In",
            body: "Just checking in - how are you doing today?",
            type: .checkIn,
            timing: .scheduled(Date().addingTimeInterval(172800)), // 48 hours from now
            disguiseNotifications: UserDefaults.standard.bool(forKey: "disguiseNotifications")
        )
    }
    
    // Check for pending notifications that match reports
    func checkForReportNotifications(reports: [Report]) {
        // Find report updates that should trigger notifications
        for report in reports {
            // Skip if report has no status updates
            guard !report.statusUpdates.isEmpty else { continue }
            
            // Get latest status update
            if let latestUpdate = report.statusUpdates.sorted(by: { $0.timestamp > $1.timestamp }).first {
                // Check if we already have a notification for this update
                let notificationExists = pendingNotifications.contains(where: { 
                    $0.referenceID == report.id && $0.createdAt > latestUpdate.timestamp.addingTimeInterval(-60)
                }) || readNotifications.contains(where: { 
                    $0.referenceID == report.id && $0.createdAt > latestUpdate.timestamp.addingTimeInterval(-60)
                })
                
                // If no notification exists for this update, create one
                if !notificationExists {
                    let notification = createReportStatusNotification(report: report, update: latestUpdate)
                    scheduleNotification(for: notification)
                }
            }
        }
        
        // Save the last check time
        UserDefaults.standard.set(Date(), forKey: Keys.lastCheckTime)
    }
    
    // Save notifications to UserDefaults
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(pendingNotifications) {
            UserDefaults.standard.set(encoded, forKey: Keys.pendingNotifications)
        }
        
        if let encoded = try? JSONEncoder().encode(readNotifications) {
            UserDefaults.standard.set(encoded, forKey: Keys.readNotifications)
        }
    }
    
    // Load notifications from UserDefaults
    private func loadSavedNotifications() {
        if let data = UserDefaults.standard.data(forKey: Keys.pendingNotifications),
           let notifications = try? JSONDecoder().decode([AppNotification].self, from: data) {
            pendingNotifications = notifications
        }
        
        if let data = UserDefaults.standard.data(forKey: Keys.readNotifications),
           let notifications = try? JSONDecoder().decode([AppNotification].self, from: data) {
            readNotifications = notifications
        }
    }
    
    // Clear all notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        pendingNotifications = []
        readNotifications = []
        saveNotifications()
        resetBadgeCount()
    }
}

// Notification model
class AppNotification: Identifiable, Codable, ObservableObject {
    let id: String
    let title: String
    let body: String
    let type: NotificationType
    let timing: NotificationTiming
    let createdAt: Date
    let referenceID: String?
    let disguiseNotifications: Bool
    
    @Published var isRead: Bool = false
    @Published var readAt: Date?
    
    enum NotificationType: String, Codable {
        case reportUpdate
        case draftReminder
        case checkIn
        case actionRequired
        case appUpdate
        case securityAlert
    }
    
    enum NotificationTiming: Codable {
        case immediate
        case delayed(Int)
        case scheduled(Date)
        
        private enum CodingKeys: String, CodingKey {
            case type, value
        }
        
        enum TimingType: String, Codable {
            case immediate, delayed, scheduled
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(TimingType.self, forKey: .type)
            
            switch type {
            case .immediate:
                self = .immediate
            case .delayed:
                let seconds = try container.decode(Int.self, forKey: .value)
                self = .delayed(seconds)
            case .scheduled:
                let date = try container.decode(Date.self, forKey: .value)
                self = .scheduled(date)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .immediate:
                try container.encode(TimingType.immediate, forKey: .type)
            case .delayed(let seconds):
                try container.encode(TimingType.delayed, forKey: .type)
                try container.encode(seconds, forKey: .value)
            case .scheduled(let date):
                try container.encode(TimingType.scheduled, forKey: .type)
                try container.encode(date, forKey: .value)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, type, timing, createdAt, referenceID, isRead, readAt, disguiseNotifications
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         body: String,
         type: NotificationType,
         timing: NotificationTiming,
         referenceID: String? = nil,
         isRead: Bool = false,
         readAt: Date? = nil,
         disguiseNotifications: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.timing = timing
        self.createdAt = Date()
        self.referenceID = referenceID
        self.isRead = isRead
        self.readAt = readAt
        self.disguiseNotifications = disguiseNotifications
    }
    
    // Custom decoder init to handle @Published properties
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        type = try container.decode(NotificationType.self, forKey: .type)
        timing = try container.decode(NotificationTiming.self, forKey: .timing)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        referenceID = try container.decodeIfPresent(String.self, forKey: .referenceID)
        disguiseNotifications = try container.decode(Bool.self, forKey: .disguiseNotifications)
        
        // Decode the @Published properties
        isRead = try container.decode(Bool.self, forKey: .isRead)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
    }
    
    // Custom encode method to handle @Published properties
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(type, forKey: .type)
        try container.encode(timing, forKey: .timing)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(referenceID, forKey: .referenceID)
        try container.encode(disguiseNotifications, forKey: .disguiseNotifications)
        
        // Encode the @Published properties by accessing their current values
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(readAt, forKey: .readAt)
    }
    
    // Mark notification as read
    func markAsRead() {
        isRead = true
        readAt = Date()
    }
}



// Extension to check if UserDefaults contains a key
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

// App delegate for handling notifications when the app is not active
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap when app is in background
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Get notification ID
        if let id = userInfo["id"] as? String {
            // Mark notification as read
            NotificationManager.shared.markAsRead(id: id)
            
            // Process notification based on type
            if let typeString = userInfo["type"] as? String,
               let type = AppNotification.NotificationType(rawValue: typeString) {
                
                switch type {
                case .reportUpdate, .actionRequired:
                    if let reportID = userInfo["reference_id"] as? String {
                        // Would set navigation state to show report details
                        print("Should navigate to report: \(reportID)")
                    }
                case .draftReminder:
                    if let reportID = userInfo["reference_id"] as? String {
                        // Would set navigation state to edit draft
                        print("Should navigate to edit draft: \(reportID)")
                    }
                case .checkIn:
                    // Would set state to show check-in dialog
                    print("Should show check-in dialog")
                case .appUpdate:
                    // Would set state to show app update info
                    print("Should show app update info")
                case .securityAlert:
                    // Would set state to show security alert
                    print("Should show security alert")
                }
            }
        }
        
        completionHandler()
    }
}
