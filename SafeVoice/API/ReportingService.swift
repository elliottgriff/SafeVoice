//
//  ReportingService.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import Combine

// Main API service for handling reports
class ReportingService {
    // Singleton instance
    static let shared = ReportingService()
    
    private init() {}
    
    // API endpoints
    private enum Endpoint {
        static let baseURL = "https://api.safevoice.org/v1" // Will be replaced with actual API
        static let reports = baseURL + "/reports"
        static let resources = baseURL + "/resources"
        static let auth = baseURL + "/auth"
    }
    
    // Result type for API responses
    enum APIError: Error {
        case networkError(Error)
        case serverError(Int)
        case decodingError(Error)
        case encodingError(Error)
        case unauthorized
        case unknown
    }
    
    // Submit a report to the API
    func submitReport(_ report: Report, attachments: [AttachmentData] = []) -> AnyPublisher<ReportResponse, APIError> {
        // Encrypt report data
        guard let encryptedReport = encryptReportData(report) else {
            return Fail(error: APIError.encodingError(NSError(domain: "Encryption failed", code: -1))).eraseToAnyPublisher()
        }
        
        // Create request
        var request = URLRequest(url: URL(string: Endpoint.reports)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create multipart request if there are attachments
        if !attachments.isEmpty {
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = createMultipartBody(reportData: encryptedReport, attachments: attachments, boundary: boundary)
        } else {
            // Just send the report JSON
            request.httpBody = encryptedReport
        }
        
        // Add anonymity headers
        if report.isAnonymous {
            request.setValue("true", forHTTPHeaderField: "X-Anonymous-Report")
        }
        
        // Execute the request
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<ReportResponse, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                // Check for server errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.serverError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                // Decode the response
                return Just(data)
                    .decode(type: ReportResponse.self, decoder: JSONDecoder())
                    .mapError { APIError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Get local resources (shelters, hotlines, etc.)
    func getLocalResources(latitude: Double, longitude: Double) -> AnyPublisher<[Resource], APIError> {
        // Create URL with location parameters
        guard var urlComponents = URLComponents(string: Endpoint.resources) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: "50") // 50 mile radius
        ]
        
        guard let url = urlComponents.url else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Execute the request
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<[Resource], APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                // Check for server errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.serverError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                // Decode the response
                return Just(data)
                    .decode(type: [Resource].self, decoder: JSONDecoder())
                    .mapError { APIError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Helper method to encrypt report data
    private func encryptReportData(_ report: Report) -> Data? {
        do {
            // Convert report to JSON data
            let jsonData = try JSONEncoder().encode(report)
            
            // In a real implementation, we would encrypt this data
            // For this prototype, we'll just return the JSON data
            return jsonData
        } catch {
            print("Error encoding report: \(error)")
            return nil
        }
    }
    
    // Helper method to create multipart form data for file uploads
    private func createMultipartBody(reportData: Data, attachments: [AttachmentData], boundary: String) -> Data {
        var body = Data()
        
        // Add report data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"report\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(reportData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add each attachment
        for (index, attachment) in attachments.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"attachment\(index)\"; filename=\"\(attachment.filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(attachment.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(attachment.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add final boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}
