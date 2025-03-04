//
//  ReportingService.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//


import Foundation
import Combine

class ReportingService {
    static let shared = ReportingService()
    
    private init() {}
    
    private enum Endpoint {
        static let baseURL = "https://api.safevoice.org/" // fake api
        static let reports = baseURL + "/reports"
        static let resources = baseURL + "/resources"
        static let auth = baseURL + "/auth"
    }
    
    enum APIError: Error {
        case networkError(Error)
        case serverError(Int)
        case decodingError(Error)
        case encodingError(Error)
        case unauthorized
        case unknown
    }
    
    func submitReport(_ report: Report, attachments: [AttachmentData] = []) -> AnyPublisher<ReportResponse, APIError> {
        guard let encryptedReport = encryptReportData(report) else {
            return Fail(error: APIError.encodingError(NSError(domain: "Encryption failed", code: -1))).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: URL(string: Endpoint.reports)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !attachments.isEmpty {
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = createMultipartBody(reportData: encryptedReport, attachments: attachments, boundary: boundary)
        } else {
            request.httpBody = encryptedReport
        }
        
        // anonymity headers
        if report.isAnonymous {
            request.setValue("true", forHTTPHeaderField: "X-Anonymous-Report")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<ReportResponse, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.serverError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: ReportResponse.self, decoder: JSONDecoder())
                    .mapError { APIError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Get local resources (shelters, hotlines, etc.)
    func getLocalResources(latitude: Double, longitude: Double) -> AnyPublisher<[Resource], APIError> {
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<[Resource], APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.serverError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: [Resource].self, decoder: JSONDecoder())
                    .mapError { APIError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func encryptReportData(_ report: Report) -> Data? {
        do {
            let jsonData = try JSONEncoder().encode(report)
            
            // will encrypt this data when live
            return jsonData
        } catch {
            print("Error encoding report: \(error)")
            return nil
        }
    }
    
    // create multipart form data for file uploads
    private func createMultipartBody(reportData: Data, attachments: [AttachmentData], boundary: String) -> Data {
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"report\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(reportData)
        body.append("\r\n".data(using: .utf8)!)
        
        for (index, attachment) in attachments.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"attachment\(index)\"; filename=\"\(attachment.filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(attachment.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(attachment.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}
