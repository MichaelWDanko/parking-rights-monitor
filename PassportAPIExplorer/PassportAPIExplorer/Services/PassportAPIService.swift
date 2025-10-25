//
//  PassportAPIService.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/21/25.
//

import Foundation
import Combine

// MARK: - Configuration and Secrets

struct OAuthConfiguration {
    let tokenURL: URL
    let client_id: String
    let client_secret: String
    let audience: String
    let clientTraceId: String
}

enum SecretsError: Error { case fileMissing, decodeFailed }

enum SecretsLoader {
    struct Secrets: Decodable { let client_id: String; let client_secret: String }

    static func load() throws -> Secrets {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "json") else {
            throw NSError(domain: "Secrets", code: -1, userInfo: [NSLocalizedDescriptionKey: "Secrets.json file not found. Please create a Secrets.json file with your client_id and client_secret."])
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Secrets.self, from: data)
        } catch {
            throw NSError(domain: "Secrets", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Secrets.json: \(error.localizedDescription). Make sure the file contains valid JSON with client_id and client_secret fields."])
        }
    }
}

// MARK: - Token Management

@MainActor
private struct OAuthTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String?
    let expires_at: String?
    
    enum CodingKeys: String, CodingKey {
        case access_token
        case token_type
        case expires_in
        case scope
        case expires_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        access_token = try container.decode(String.self, forKey: .access_token)
        token_type = try container.decodeIfPresent(String.self, forKey: .token_type) ?? "Bearer"
        scope = try container.decodeIfPresent(String.self, forKey: .scope)
        expires_at = try container.decodeIfPresent(String.self, forKey: .expires_at)
        
        // Handle expires_in calculation
        if let expiresIn = try? container.decode(Int.self, forKey: .expires_in) {
            expires_in = expiresIn
        } else if let expiresAtString = try? container.decodeIfPresent(String.self, forKey: .expires_at) {
            // Calculate expires_in from expires_at timestamp
            let formatter = ISO8601DateFormatter()
            if let expiresAt = formatter.date(from: expiresAtString) {
                expires_in = Int(expiresAt.timeIntervalSinceNow)
            } else {
                expires_in = 3600 // Default 1 hour fallback
            }
        } else {
            expires_in = 3600 // Default 1 hour fallback
        }
    }
}

private protocol TokenStore {
    var accessToken: String? { get async }
    var expiryDate: Date? { get async }
    func save(token: String, expiresAt: Date) async
    func clear() async
}

private final class InMemoryTokenStore: TokenStore {
    private var _accessToken: String?
    private var _expiryDate: Date?
    
    init() {}
    
    var accessToken: String? { get async { _accessToken } }
    var expiryDate: Date? { get async { _expiryDate } }
    
    func save(token: String, expiresAt: Date) async {
        _accessToken = token
        _expiryDate = expiresAt
    }
    
    func clear() async {
        _accessToken = nil
        _expiryDate = nil
    }
}

private actor TokenManager {
    private let config: OAuthConfiguration
    private let session: URLSession
    private let store: TokenStore

    init(config: OAuthConfiguration, session: URLSession = .shared, store: TokenStore? = nil) {
        self.config = config
        self.session = session
        self.store = store ?? InMemoryTokenStore()
    }

    func validAccessToken() async throws -> String {
        if let t = await store.accessToken, let exp = await store.expiryDate, Date() < exp.addingTimeInterval(-60) {
            return t
        }
        return try await fetchNewToken()
    }

    func invalidate() async { await store.clear() }

    private func fetchNewToken() async throws -> String {
        // x-www-form-urlencoded body (client_id/secret IN BODY).
        let items = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "audience", value: config.audience),
            URLQueryItem(name: "client_id", value: config.client_id),
            URLQueryItem(name: "client_secret", value: config.client_secret)
        ].filter { ($0.value ?? "").isEmpty == false }
        var comps = URLComponents(); comps.queryItems = items

        var req = URLRequest(url: config.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(config.clientTraceId, forHTTPHeaderField: "Passport-Labs-Client-Trace-Id")
        req.httpBody = comps.query?.data(using: .utf8)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "OAuth", code: code, userInfo: [NSLocalizedDescriptionKey: "Token endpoint \(code): \(body)"])
        }

        // Add debugging information
        let responseString = String(data: data, encoding: .utf8) ?? "<no response>"
        print("OAuth Response: \(responseString)")
        
        do {
            let tok = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            
            // Use expires_at timestamp if available, otherwise calculate from expires_in
            let expiresAt: Date
            if let expiresAtString = tok.expires_at {
                let formatter = ISO8601DateFormatter()
                expiresAt = formatter.date(from: expiresAtString) ?? Date().addingTimeInterval(TimeInterval(tok.expires_in))
            } else {
                expiresAt = Date().addingTimeInterval(TimeInterval(tok.expires_in))
            }
            
            await store.save(token: tok.access_token, expiresAt: expiresAt)
            return tok.access_token
        } catch {
            // Provide more specific error information
            if let decodingError = error as? DecodingError {
                let errorMessage = "JSON Decoding Error: \(decodingError.localizedDescription). Response: \(responseString)"
                throw NSError(domain: "OAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                let errorMessage = "Token parsing failed: \(error.localizedDescription). Response: \(responseString)"
                throw NSError(domain: "OAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        }
    }
}

// MARK: - Consolidated PassportAPIService

final class PassportAPIService: ObservableObject {
    private let tokenManager: TokenManager
    private let session: URLSession
    private let clientTraceId: String
    private let baseURL = "https://api.us.passportinc.com"
    
    init(config: OAuthConfiguration, session: URLSession = .shared, clientTraceId: String = "danko-test") {
        self.tokenManager = TokenManager(config: config, session: session)
        self.session = session
        self.clientTraceId = clientTraceId
    }
    
    // MARK: - Public API Methods
    
    /// Get a valid access token (useful for testing)
    func getValidToken() async throws -> String {
        return try await tokenManager.validAccessToken()
    }
    
    /// Debug method to test OAuth token endpoint and see raw response
    @MainActor
    func debugTokenEndpoint() async throws -> String {
        let secrets = try SecretsLoader.load()
        let config = OAuthConfiguration(
            tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
            client_id: secrets.client_id,
            client_secret: secrets.client_secret,
            audience: "public.api.passportinc.com",
            clientTraceId: "danko-test"
        )
        
        let items = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "audience", value: config.audience),
            URLQueryItem(name: "client_id", value: config.client_id),
            URLQueryItem(name: "client_secret", value: config.client_secret)
        ].filter { ($0.value ?? "").isEmpty == false }
        var comps = URLComponents(); comps.queryItems = items

        var req = URLRequest(url: config.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(config.clientTraceId, forHTTPHeaderField: "Passport-Labs-Client-Trace-Id")
        req.httpBody = comps.query?.data(using: .utf8)

        let (data, resp) = try await session.data(for: req)
        let responseString = String(data: data, encoding: .utf8) ?? "<no response>"
        
        if let http = resp as? HTTPURLResponse {
            return "Status: \(http.statusCode)\nResponse: \(responseString)"
        } else {
            return "No HTTP response\nResponse: \(responseString)"
        }
    }
    
    func fetchZones(forOperatorId operatorId: String) async throws -> [Zone] {
        let url = URL(string: "\(baseURL)/v3/shared/zones?operator_id=\(operatorId.lowercased())")!
        print("🏢 Fetching zones for operator: \(operatorId)")
        print("🏢 URL: \(url.absoluteString)")
        
        // Create a wrapper response model for the API
        struct ZonesResponse: Codable {
            let data: [Zone]
        }
        
        do {
            let response = try await performAuthenticatedRequest(url: url, responseType: ZonesResponse.self)
            print("🏢 API returned \(response.data.count) zones")
            for (index, zone) in response.data.enumerated() {
                print("🏢 Zone \(index + 1): \(zone.name) (ID: \(zone.id))")
            }
            return response.data
        } catch {
            print("🏢 Error fetching zones: \(error)")
            // Try to provide more specific error information
            if let decodingError = error as? DecodingError {
                print("🏢 Decoding error details: \(decodingError)")
            }
            throw error
        }
    }
//    
//    func fetchParkingRightsByZone(forZoneId zoneId: String) async throws -> [ParkingRight] {
//        let url = URL(string: "\(baseURL)/zones/\(zoneId)/parking-rights")!
//        return try await performAuthenticatedRequest(url: url, responseType: [ParkingRight].self)
//    }
    
    // MARK: - Convenience Methods
    
    /// Fetches parking rights for multiple zones in parallel
//    func fetchParkingRights(for zoneIds: [String]) async throws -> [String: [ParkingRight]] {
//        return try await withThrowingTaskGroup(of: (String, [ParkingRight]).self) { group in
//            var results: [String: [ParkingRight]] = [:]
//            
//            for zoneId in zoneIds {
//                group.addTask {
//                    let parkingRights = try await self.fetchParkingRights(for: zoneId)
//                    return (zoneId, parkingRights)
//                }
//            }
//            
//            for try await (zoneId, parkingRights) in group {
//                results[zoneId] = parkingRights
//            }
//            
//            return results
//        }
//    }
    
    /// Fetches all zones for an operator and their parking rights
//    func fetchZonesWithParkingRights(for operatorId: String) async throws -> [Zone: [ParkingRight]] {
//        let zones = try await fetchZones(for: operatorId)
//        let zoneIds = zones.map { $0.id }
//        let parkingRightsByZone = try await fetchParkingRights(for: zoneIds)
//        
//        var result: [Zone: [ParkingRight]] = [:]
//        for zone in zones {
//            result[zone] = parkingRightsByZone[zone.id] ?? []
//        }
//        
//        return result
//    }
//    
//    func fetchParkingRightsByZone(forZoneId zoneId: String) async throws -> [ParkingRight] {
//        let url = URL(string: "\(baseURL)/zones/\(zoneId)/parking-rights")!
//        return try await performAuthenticatedRequest(url: url, responseType: [ParkingRight].self)
//    }
    
    // MARK: - Convenience Methods
    
    /// Fetches parking rights for multiple zones in parallel
//    func fetchParkingRights(for zoneIds: [String]) async throws -> [String: [ParkingRight]] {
//        return try await withThrowingTaskGroup(of: (String, [ParkingRight]).self) { group in
//            var results: [String: [ParkingRight]] = [:]
//            
//            for zoneId in zoneIds {
//                group.addTask {
//                    let parkingRights = try await self.fetchParkingRights(for: zoneId)
//                    return (zoneId, parkingRights)
//                }
//            }
//            
//            for try await (zoneId, parkingRights) in group {
//                results[zoneId] = parkingRights
//            }
//            
//            return results
//        }
//    }
    
    /// Fetches all zones for an operator and their parking rights
//    func fetchZonesWithParkingRights(for operatorId: String) async throws -> [Zone: [ParkingRight]] {
//        let zones = try await fetchZones(for: operatorId)
//        let zoneIds = zones.map { $0.id }
//        let parkingRightsByZone = try await fetchParkingRights(for: zoneIds)
//        
//        var result: [Zone: [ParkingRight]] = [:]
//        for zone in zones {
//            result[zone] = parkingRightsByZone[zone.id] ?? []
//        }
//        
//        return result
//    }
    
    func fetchParkingRights(forOperatorId operatorId: String, zoneId: String) async throws -> [ParkingRight] {
        // Build URL with proper query parameters
        var components = URLComponents(string: "\(baseURL)/v4/enforcement/parking-rights")!
        components.queryItems = [
            URLQueryItem(name: "operator_id", value: operatorId.lowercased()),
            URLQueryItem(name: "zone_id", value: zoneId)
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL"])
        }
        
        print("🚗 Fetching parking rights for operator: \(operatorId), zone: \(zoneId)")
        print("🚗 URL: \(url.absoluteString)")
        print("🚗 Query parameters: operator_id=\(operatorId.lowercased()), zone_id=\(zoneId)")
        
        // Create a wrapper response model for the API
        struct ParkingRightsResponse: Codable {
            let data: [ParkingRight]
        }
        
        do {
            let response = try await performAuthenticatedRequest(url: url, responseType: ParkingRightsResponse.self)
            print("🚗 API returned \(response.data.count) parking rights")
            for (index, parkingRight) in response.data.enumerated() {
                print("🚗 Parking Right \(index + 1): \(parkingRight.id)")
                print("🔍 Getting vehicle_plate: \(parkingRight.vehicle_plate ?? "nil")")
                print("🚗   - Vehicle: \(parkingRight.vehicle_plate ?? "N/A") (\(parkingRight.vehicle_state ?? "N/A"))")
                print("🚗   - Time: \(parkingRight.start_time) to \(parkingRight.end_time)")
                print("🚗   - Reference: \(parkingRight.reference_id ?? "N/A")")
            }
            return response.data
        } catch {
            print("🚗 Error fetching parking rights: \(error)")
            print("🚗 Error details: \(error.localizedDescription)")
            
            // Try to provide more specific error information
            if let decodingError = error as? DecodingError {
                print("🚗 Decoding error details: \(decodingError)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("🚗 Type mismatch: expected \(type), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("🚗 Value not found: \(type), context: \(context)")
                case .keyNotFound(let key, let context):
                    print("🚗 Key not found: \(key), context: \(context)")
                case .dataCorrupted(let context):
                    print("🚗 Data corrupted: \(context)")
                @unknown default:
                    print("🚗 Unknown decoding error")
                }
            }
            
            // Log the raw response if available
            if let urlError = error as? URLError {
                print("🚗 URL Error: \(urlError.localizedDescription)")
            }
            
            throw error
        }
    }
    
    // MARK: - Private Network Methods
    
    private func performAuthenticatedRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        let request = try await createAuthenticatedRequest(url: url)
        let (data, _) = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let result = try decoder.decode(responseType, from: data)
            print("🔍 Successfully decoded \(responseType)")
            return result
        } catch {
            print("🔍 JSON Decoding failed: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("🔍 Type mismatch: expected \(type), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("🔍 Value not found: \(type), context: \(context)")
                case .keyNotFound(let key, let context):
                    print("🔍 Key not found: \(key), context: \(context)")
                case .dataCorrupted(let context):
                    print("🔍 Data corrupted: \(context)")
                @unknown default:
                    print("🔍 Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    private func createAuthenticatedRequest(url: URL, method: String = "GET") async throws -> URLRequest {
        let token = try await tokenManager.validAccessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(clientTraceId, forHTTPHeaderField: "Passport-Labs-Client-Trace-Id")
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        print("🌐 Making request to: \(request.url?.absoluteString ?? "unknown")")
        print("🌐 Method: \(request.httpMethod ?? "unknown")")
        print("🌐 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🌐 Response status: \(httpResponse.statusCode)")
        
        // Log the raw response body for debugging
        if let responseBody = String(data: data, encoding: .utf8) {
            print("🌐 Raw response body: \(responseBody)")
        } else {
            print("🌐 Could not decode response body as UTF-8")
        }
        
        // Log response headers for debugging
        print("🌐 Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode == 401 {
            // Token expired, invalidate and retry once
            await tokenManager.invalidate()
            let newToken = try await tokenManager.validAccessToken()
            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(retryHttpResponse.statusCode) else {
                throw httpError(retryHttpResponse.statusCode, retryData)
            }
            return (retryData, retryHttpResponse)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw httpError(httpResponse.statusCode, data)
        }
        
        return (data, httpResponse)
    }
    
    private func httpError(_ statusCode: Int, _ data: Data) -> Error {
        let body = String(data: data, encoding: .utf8) ?? ""
        return NSError(domain: "HTTP", code: statusCode, userInfo: [NSLocalizedDescriptionKey: body])
    }
}
