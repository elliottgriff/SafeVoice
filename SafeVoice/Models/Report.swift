//
//  Report.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import Combine

struct Report: Identifiable, Codable {
    var id: String
    var timestamp: Date
    var reportType: ReportType
    var content: String
    var mediaAttachments: [MediaAttachment] = []
    var isAnonymous: Bool = true
    var status: ReportStatus = .submitted
    var userID: String?
    var trackingCode: String?
    var statusUpdates: [StatusUpdate] = []
    var locationData: LocationData?
    var contactInfo: ContactInfo?
    var metadata: [String: String] = [:]
    
    enum ReportType: String, Codable, CaseIterable {
        case physical, emotional, neglect, sexual, bullying, other
        
        var displayName: String {
            switch self {
            case .physical: return "Physical Abuse"
            case .emotional: return "Emotional Abuse"
            case .neglect: return "Neglect"
            case .sexual: return "Sexual Abuse"
            case .bullying: return "Bullying"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .physical: return "hand.raised.slash.fill"
            case .emotional: return "heart.slash.fill"
            case .neglect: return "xmark.circle.fill"
            case .sexual: return "exclamationmark.shield.fill"
            case .bullying: return "person.2.slash.fill"
            case .other: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .physical: return "#FF3B30" // Red
            case .emotional: return "#AF52DE" // Purple
            case .neglect: return "#007AFF" // Blue
            case .sexual: return "#FF9500" // Orange
            case .bullying: return "#34C759" // Green
            case .other: return "#8E8E93" // Gray
            }
        }
    }
    
    enum ReportStatus: String, Codable {
        case drafted, submitted, received, inProgress, resolved
        
        var displayName: String {
            switch self {
            case .drafted: return "Draft"
            case .submitted: return "Submitted"
            case .received: return "Received"
            case .inProgress: return "In Progress"
            case .resolved: return "Resolved"
            }
        }
    }
    
    static func createNew(reportType: ReportType = .other) -> Report {
        Report(
            id: UUID().uuidString,
            timestamp: Date(),
            reportType: reportType,
            content: "",
            status: .drafted
        )
    }
    
    mutating func addStatusUpdate(_ update: StatusUpdate) {
        statusUpdates.append(update)
        self.status = update.newStatus
    }
}

struct MediaAttachment: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: AttachmentType
    var url: URL?
    var localPath: String?
    var thumbnail: Data?
    var mimeType: String?
    var filename: String?
    var size: Int?
    var metadata: [String: String] = [:]
    
    enum AttachmentType: String, Codable {
        case image, audio, video, document
    }
}

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var placeName: String?
    var timestamp: Date
}

struct ContactInfo: Codable {
    var name: String?
    var email: String?
    var phone: String?
    var preferredContactMethod: ContactMethod
    
    enum ContactMethod: String, Codable {
        case none, email, phone, both
    }
}

struct StatusUpdate: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var oldStatus: Report.ReportStatus
    var newStatus: Report.ReportStatus
    var message: String
    var agentID: String?
    var actionRequired: Bool = false
    var actionType: ActionType?
    
    enum ActionType: String, Codable {
        case additionalInfo, confirmation, callback, other
    }
}

class ReportStore: ObservableObject {
    @Published var activeReports: [Report] = []
    @Published var draftReports: [Report] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private enum Keys {
        static let activeReports = "activeReports"
        static let draftReports = "draftReports"
    }
    
    init() {
        loadFromStorage()
    }
    
    func submitReport(_ report: Report, completion: @escaping (Result<Report, Error>) -> Void) {
        isLoading = true
        
        var finalReport = report
        
        if finalReport.status == .drafted {
            finalReport.status = .submitted
        }
        
        if finalReport.id.isEmpty {
            finalReport.id = UUID().uuidString
            finalReport.timestamp = Date()
        }
        
        // In a real implementation, we would call the API
        // For now, we'll simulate network delay and success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate server-side tracking code generation
            finalReport.trackingCode = String(format: "%@-%05d", 
                                             finalReport.id.prefix(4).uppercased(),
                                             Int.random(in: 10000...99999))
            
            // Remove from drafts if it was a draft
            if let index = self.draftReports.firstIndex(where: { $0.id == finalReport.id }) {
                self.draftReports.remove(at: index)
            }
            
            // Add to active reports or update existing
            if let index = self.activeReports.firstIndex(where: { $0.id == finalReport.id }) {
                self.activeReports[index] = finalReport
            } else {
                self.activeReports.append(finalReport)
            }
            
            self.saveToStorage()
            self.isLoading = false
            completion(.success(finalReport))
        }
    }
    
    func saveDraft(_ report: Report) {
        var draftReport = report
        
        draftReport.status = .drafted
        
        if draftReport.id.isEmpty {
            draftReport.id = UUID().uuidString
            draftReport.timestamp = Date()
        }
        
        if let index = draftReports.firstIndex(where: { $0.id == draftReport.id }) {
            draftReports[index] = draftReport
        } else {
            draftReports.append(draftReport)
        }
        
        saveToStorage()
    }
    
    func deleteReport(id: String) {
        if let index = activeReports.firstIndex(where: { $0.id == id }) {
            activeReports.remove(at: index)
        }
        
        if let index = draftReports.firstIndex(where: { $0.id == id }) {
            draftReports.remove(at: index)
        }
        
        saveToStorage()
    }
    
    func addStatusUpdate(reportID: String, update: StatusUpdate, completion: @escaping (Bool) -> Void) {
        guard var report = getReport(id: reportID) else {
            completion(false)
            return
        }
        
        report.addStatusUpdate(update)
        report.status = update.newStatus
        
        if let index = activeReports.firstIndex(where: { $0.id == reportID }) {
            activeReports[index] = report
            saveToStorage()
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func getReport(id: String) -> Report? {
        if let report = activeReports.first(where: { $0.id == id }) {
            return report
        }
        
        if let report = draftReports.first(where: { $0.id == id }) {
            return report
        }
        
        return nil
    }
    
    func checkForUpdates() {
        isLoading = true
        
        // In a real implementation, we would call the API
        // For now, simulate network delay and randomly update a report
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            
            // If there are active reports, randomly update one
            if !self.activeReports.isEmpty && Int.random(in: 1...3) == 1 {
                let randomIndex = Int.random(in: 0..<self.activeReports.count)
                if self.activeReports[randomIndex].status != .resolved {
                    let newStatuses: [Report.ReportStatus] = [.received, .inProgress, .resolved]
                    
                    // Find a status that's "newer" than the current one
                    let currentStatus = self.activeReports[randomIndex].status
                    let possibleNewStatuses = newStatuses.filter {
                        self.statusRank($0) > self.statusRank(currentStatus)
                    }
                    
                    if let newStatus = possibleNewStatuses.randomElement() {
                        var updatedReport = self.activeReports[randomIndex]
                        
                        let statusUpdate = StatusUpdate(
                            timestamp: Date(),
                            oldStatus: updatedReport.status,
                            newStatus: newStatus,
                            message: self.messageForStatus(newStatus)
                        )
                        
                        updatedReport.addStatusUpdate(statusUpdate)
                        self.activeReports[randomIndex] = updatedReport
                        self.saveToStorage()
                    }
                }
            }
            
            self.isLoading = false
        }
    }
    
    // Helper to determine status rank for comparison
    private func statusRank(_ status: Report.ReportStatus) -> Int {
        switch status {
        case .drafted: return 0
        case .submitted: return 1
        case .received: return 2
        case .inProgress: return 3
        case .resolved: return 4
        }
    }
    
    // Helper to generate status update messages
    private func messageForStatus(_ status: Report.ReportStatus) -> String {
        switch status {
        case .drafted:
            return "Report saved as draft."
        case .submitted:
            return "Thank you for your report. It has been submitted successfully."
        case .received:
            return "Your report has been received and is under review by our team."
        case .inProgress:
            return "Your report is now being handled by a case worker who will take appropriate action."
        case .resolved:
            return "Your report has been resolved. Thank you for helping make a difference."
        }
    }
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(activeReports) {
            UserDefaults.standard.set(encoded, forKey: Keys.activeReports)
        }
        
        if let encoded = try? JSONEncoder().encode(draftReports) {
            UserDefaults.standard.set(encoded, forKey: Keys.draftReports)
        }
    }
    
    private func loadFromStorage() {
        if let activeData = UserDefaults.standard.data(forKey: Keys.activeReports),
           let loadedActiveReports = try? JSONDecoder().decode([Report].self, from: activeData) {
            activeReports = loadedActiveReports
        }
        
        if let draftData = UserDefaults.standard.data(forKey: Keys.draftReports),
           let loadedDraftReports = try? JSONDecoder().decode([Report].self, from: draftData) {
            draftReports = loadedDraftReports
        }
    }
    
    // Clear all reports (for use with privacy features)
    func clearAllReports() {
        activeReports = []
        draftReports = []
        saveToStorage()
    }
}

// Report media handling extension
extension ReportStore {
    func addMediaAttachment(reportID: String, attachment: MediaAttachment) -> Bool {
        guard var report = getReport(id: reportID) else {
            return false
        }
        
        report.mediaAttachments.append(attachment)
        
        if report.status == .drafted {
            if let index = draftReports.firstIndex(where: { $0.id == reportID }) {
                draftReports[index] = report
                saveToStorage()
                return true
            }
        } else {
            if let index = activeReports.firstIndex(where: { $0.id == reportID }) {
                activeReports[index] = report
                saveToStorage()
                return true
            }
        }
        
        return false
    }
    
    func removeMediaAttachment(reportID: String, attachmentID: String) -> Bool {
        guard var report = getReport(id: reportID) else {
            return false
        }
        
        if let attachmentIndex = report.mediaAttachments.firstIndex(where: { $0.id == attachmentID }) {
            report.mediaAttachments.remove(at: attachmentIndex)
            
            if report.status == .drafted {
                if let index = draftReports.firstIndex(where: { $0.id == reportID }) {
                    draftReports[index] = report
                    saveToStorage()
                    return true
                }
            } else {
                if let index = activeReports.firstIndex(where: { $0.id == reportID }) {
                    activeReports[index] = report
                    saveToStorage()
                    return true
                }
            }
        }
        
        return false
    }
    
    // Save media file to local storage and update attachment with path
    func saveMedia(data: Data, filename: String, mimeType: String, completion: @escaping (MediaAttachment?) -> Void) {
        // In a real app, would save to app's Documents directory
        // For demo, we'll just create the attachment with data as thumbnail
        
        let type: MediaAttachment.AttachmentType
        if mimeType.contains("image") {
            type = .image
        } else if mimeType.contains("audio") {
            type = .audio
        } else if mimeType.contains("video") {
            type = .video
        } else {
            type = .document
        }
        
        let attachment = MediaAttachment(
            type: type,
            thumbnail: type == .image ? data : nil,
            mimeType: mimeType,
            filename: filename,
            size: data.count
        )
        
        // In a real app, we would save the file to disk
        // and set the localPath property
        
        completion(attachment)
    }
}
