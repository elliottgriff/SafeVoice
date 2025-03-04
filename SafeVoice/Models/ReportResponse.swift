//
//  ReportResponse.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation

struct ReportResponse: Codable {
    let id: String
    let timestamp: Date
    let status: String
    let trackingCode: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case status
        case trackingCode = "tracking_code"
        case message
    }
}

struct Resource: Codable, Identifiable {
    let id: String
    let name: String
    let type: ResourceType
    let description: String
    let phoneNumber: String?
    let website: URL?
    let address: Address?
    let hours: String?
    let services: [String]
    let emergencyService: Bool
    let latitude: Double?
    let longitude: Double?
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case description
        case phoneNumber = "phone_number"
        case website
        case address
        case hours
        case services
        case emergencyService = "emergency_service"
        case latitude
        case longitude
        case distance
    }
    
    enum ResourceType: String, Codable {
        case shelter
        case counseling
        case legalAid = "legal_aid"
        case childServices = "child_services"
        case hotline
        case medical
        case police
        case school
        case other
    }
}

struct Address: Codable {
    let street1: String
    let street2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case street1
        case street2
        case city
        case state
        case postalCode = "postal_code"
        case country
    }
}

struct AttachmentData {
    let data: Data
    let filename: String
    let mimeType: String
}

struct ReportStatusUpdate: Codable {
    let reportId: String
    let status: String
    let timestamp: Date
    let message: String?
    let actionRequired: Bool
    let actionType: ActionType?
    
    enum CodingKeys: String, CodingKey {
        case reportId = "report_id"
        case status
        case timestamp
        case message
        case actionRequired = "action_required"
        case actionType = "action_type"
    }
    
    enum ActionType: String, Codable {
        case additionalInfo = "additional_info"
        case confirmation = "confirmation"
        case callback = "callback"
        case other
    }
}

struct AnonymousProfile: Codable {
    let token: String
    let anonymousId: String
    let createdAt: Date
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case token
        case anonymousId = "anonymous_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
