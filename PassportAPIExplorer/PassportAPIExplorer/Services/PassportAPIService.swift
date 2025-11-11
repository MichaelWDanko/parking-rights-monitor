//
//  PassportAPIService.swift
//  Passport API Explorer
//
//  Created by Michael Danko on 10/21/25.
//

import Foundation
import Combine

// MARK: - Configuration and Secrets

/// OAuth 2.0 Client Credentials configuration for Passport API authentication.
/// This struct holds the credentials needed to obtain an access token using the
/// OAuth 2.0 client credentials flow (no user interaction required).
struct OAuthConfiguration {
    let baseURL: String
    let tokenURL: URL
    let client_id: String
    let client_secret: String
    let audience: String
    let clientTraceId: String
}

enum SecretsError: Error { case fileMissing, decodeFailed }

/// Loads OAuth credentials from a Secrets.json file in the app bundle.
/// This keeps sensitive credentials out of source code (Secrets.json is gitignored).
enum SecretsLoader {
    struct EnvironmentCredentials: Decodable {
        let client_id: String
        let client_secret: String
    }
    
    struct Secrets: Decodable {
        let production: EnvironmentCredentials
        let staging: EnvironmentCredentials?
        let development: EnvironmentCredentials?
    }

    /// Loads and decodes the Secrets.json file containing OAuth credentials for all environments.
    /// Throws an error if the file is missing or invalid JSON.
    static func load() throws -> Secrets {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "json") else {
            throw NSError(domain: "Secrets", code: -1, userInfo: [NSLocalizedDescriptionKey: "Secrets.json file not found. Please create a Secrets.json file with credentials for each environment."])
        }
        do {
            let data = try Data(contentsOf: url)
            
            // Log raw JSON for debugging (redact secrets)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [SecretsLoader] Raw JSON file contents:")
                // Redact actual secrets but show structure
                let redacted = jsonString
                    .replacingOccurrences(of: #""client_id"\s*:\s*"([^"]+)""#, with: #""client_id": "[REDACTED]"#, options: .regularExpression)
                    .replacingOccurrences(of: #"client_secret"\s*:\s*"([^"]+)""#, with: #"client_secret": "[REDACTED]"#, options: .regularExpression)
                print("📄 [SecretsLoader] \(redacted)")
            }
            
            let secrets = try JSONDecoder().decode(Secrets.self, from: data)
            
            // Log decoded structure
            print("📄 [SecretsLoader] Decoded Secrets structure:")
            print("📄 [SecretsLoader] - Production: \(secrets.production.client_id.prefix(8))... (secret length: \(secrets.production.client_secret.count))")
            if let staging = secrets.staging {
                print("📄 [SecretsLoader] - Staging: \(staging.client_id.prefix(8))... (secret: \"\(staging.client_secret)\")")
            } else {
                print("📄 [SecretsLoader] - Staging: nil")
            }
            if let dev = secrets.development {
                print("📄 [SecretsLoader] - Development: \(dev.client_id.prefix(8))... (secret length: \(dev.client_secret.count))")
            } else {
                print("📄 [SecretsLoader] - Development: nil")
            }
            
            return secrets
        } catch {
            print("❌ [SecretsLoader] Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ [SecretsLoader] Missing key: \(key) at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ [SecretsLoader] Type mismatch: expected \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ [SecretsLoader] Value not found: \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ [SecretsLoader] Data corrupted at \(context.codingPath): \(context.debugDescription)")
                @unknown default:
                    print("❌ [SecretsLoader] Unknown decoding error")
                }
            }
            throw NSError(domain: "Secrets", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Secrets.json: \(error.localizedDescription). Make sure the file contains valid JSON with production, staging, and development credentials."])
        }
    }
    
    /// Get credentials for a specific environment from Secrets.json
    static func credentials(for environment: OperatorEnvironment) throws -> EnvironmentCredentials? {
        print("📄 [SecretsLoader] Loading credentials for \(environment.rawValue)...")
        let secrets = try load()
        
        let result: EnvironmentCredentials?
        switch environment {
        case .production:
            result = secrets.production
            print("📄 [SecretsLoader] Production credentials found: \(result != nil)")
        case .staging:
            result = secrets.staging
            print("📄 [SecretsLoader] Staging credentials found: \(result != nil)")
        case .development:
            result = secrets.development
            print("📄 [SecretsLoader] Development credentials found: \(result != nil)")
        }
        
        if let creds = result {
            print("📄 [SecretsLoader] Raw Client ID from JSON: \"\(creds.client_id)\"")
            print("📄 [SecretsLoader] Raw Client ID length: \(creds.client_id.count) characters")
            print("📄 [SecretsLoader] Raw Client ID bytes: \(creds.client_id.data(using: .utf8)?.map { String(format: "%02x", $0) }.joined(separator: " ") ?? "N/A")")
            print("📄 [SecretsLoader] Client ID trimmed: \"\(creds.client_id.trimmingCharacters(in: .whitespacesAndNewlines))\"")
            print("📄 [SecretsLoader] Client ID trimmed length: \(creds.client_id.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
            
            print("📄 [SecretsLoader] Raw Client Secret from JSON: \"\(creds.client_secret)\"")
            print("📄 [SecretsLoader] Raw Client Secret length: \(creds.client_secret.count) characters")
            print("📄 [SecretsLoader] Client Secret trimmed: \"\(creds.client_secret.trimmingCharacters(in: .whitespacesAndNewlines))\"")
            print("📄 [SecretsLoader] Client Secret trimmed length: \(creds.client_secret.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
        } else {
            print("📄 [SecretsLoader] No credentials found for \(environment.rawValue)")
        }
        
        return result
    }
}

// MARK: - Token Management

/// Public-facing OAuth token response structure.
/// Contains the access token and metadata returned from the OAuth token endpoint.
struct TokenResponse {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String?
    let expiresAt: Date?
    
    var formattedExpiresAt: String? {
        guard let expiresAt = expiresAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expiresAt)
    }
    
    var scopesArray: [String] {
        guard let scope = scope else { return [] }
        return scope.components(separatedBy: " ").filter { !$0.isEmpty }
    }
}

/// Internal OAuth token response model matching the API's JSON structure.
/// Uses snake_case keys to match the API response format exactly.
private struct OAuthTokenResponse: Decodable, Sendable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String?
    let expires_at: String?
    
    /// Maps JSON keys (snake_case) to Swift properties (camelCase)
    enum CodingKeys: String, CodingKey {
        case access_token
        case token_type
        case expires_in
        case scope
        case expires_at
    }
    
    nonisolated init(from decoder: Decoder) throws {
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

/// Protocol for storing OAuth access tokens.
/// Allows different storage implementations (in-memory, keychain, etc.)
private protocol TokenStore {
    var accessToken: String? { get async }
    var expiryDate: Date? { get async }
    func save(token: String, expiresAt: Date) async
    func clear() async
}

/// In-memory token storage implementation.
/// Tokens are lost when the app terminates (suitable for development/testing).
private final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var _accessToken: String?
    private var _expiryDate: Date?
    
    nonisolated init() {}
    
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

/// Manages OAuth token lifecycle: fetching, caching, and refreshing tokens.
/// Uses Swift's actor model for thread-safe token management.
/// Automatically refreshes tokens when they expire (with 60-second buffer).
private actor TokenManager {
    private let config: OAuthConfiguration
    private let session: URLSession
    private let store: TokenStore

    init(config: OAuthConfiguration, session: URLSession = .shared, store: TokenStore? = nil) {
        self.config = config
        self.session = session
        self.store = store ?? InMemoryTokenStore()
    }

    /// Returns a valid access token, fetching a new one if the cached token is expired.
    /// Checks expiration with a 60-second buffer to avoid using tokens that expire soon.
    func validAccessToken() async throws -> String {
        // Check if we have a valid cached token (not expired, with 60s buffer)
        if let t = await store.accessToken, let exp = await store.expiryDate, Date() < exp.addingTimeInterval(-60) {
            return t
        }
        // Token expired or missing, fetch a new one
        return try await fetchNewToken()
    }
    
    func getTokenResponse() async throws -> TokenResponse {
        // Always fetch a fresh token to get full response details
        let response = try await fetchNewTokenResponse()
        return response
    }

    func invalidate() async { await store.clear() }

    private func fetchNewToken() async throws -> String {
        let response = try await fetchNewTokenResponse()
        await store.save(token: response.accessToken, expiresAt: response.expiresAt ?? Date().addingTimeInterval(3600))
        return response.accessToken
    }
    
    /// Fetches a new OAuth access token from the Passport API token endpoint.
    /// Uses OAuth 2.0 Client Credentials flow: sends client_id and client_secret
    /// in the request body as application/x-www-form-urlencoded data.
    private func fetchNewTokenResponse() async throws -> TokenResponse {
        print("🔑 [OAuth] Preparing token request...")
        print("🔑 [OAuth] Token URL: \(config.tokenURL)")
        print("🔑 [OAuth] Client ID from config: \"\(config.client_id)\"")
        print("🔑 [OAuth] Client ID length: \(config.client_id.count) characters")
        print("🔑 [OAuth] Client ID contains only alphanumeric: \(config.client_id.allSatisfy { $0.isLetter || $0.isNumber })")
        print("🔑 [OAuth] Client ID matches pattern [A-Za-z0-9]{32}: \(NSPredicate(format: "SELF MATCHES %@", "^[A-Za-z0-9]{32}$").evaluate(with: config.client_id))")
        print("🔑 [OAuth] Client Secret length: \(config.client_secret.count) characters")
        print("🔑 [OAuth] Audience: \(config.audience)")
        
        // Build form-encoded request body for OAuth 2.0 client credentials flow
        // Note: credentials go in the BODY, not as Basic Auth headers
        let items = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "audience", value: config.audience),
            URLQueryItem(name: "client_id", value: config.client_id),
            URLQueryItem(name: "client_secret", value: config.client_secret)
        ].filter { ($0.value ?? "").isEmpty == false }
        
        print("🔑 [OAuth] Form items count: \(items.count)")
        for item in items {
            if item.name == "client_id" {
                print("🔑 [OAuth] Form item '\(item.name)': \"\(item.value ?? "")\" (length: \(item.value?.count ?? 0))")
            } else if item.name == "client_secret" {
                print("🔑 [OAuth] Form item '\(item.name)': [REDACTED] (length: \(item.value?.count ?? 0))")
            } else {
                print("🔑 [OAuth] Form item '\(item.name)': \(item.value ?? "")")
            }
        }
        
        var comps = URLComponents(); comps.queryItems = items
        let requestBody = comps.query ?? ""
        print("🔑 [OAuth] Request body (query string): \(requestBody)")
        print("🔑 [OAuth] Request body length: \(requestBody.count) characters")

        // Create POST request to token endpoint
        var req = URLRequest(url: config.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(config.clientTraceId, forHTTPHeaderField: "Passport-Labs-Client-Trace-Id")
        req.httpBody = comps.query?.data(using: .utf8)
        
        if let bodyData = req.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔑 [OAuth] Final request body (UTF-8): \(bodyString)")
            print("🔑 [OAuth] Final request body length: \(bodyData.count) bytes")
        }

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "OAuth", code: code, userInfo: [NSLocalizedDescriptionKey: "Token endpoint \(code): \(body)"])
        }

        // Add debugging information - log full response
        let responseString = String(data: data, encoding: .utf8) ?? "<no response>"
        print("🔑 [OAuth] Full API Response:")
        print("🔑 [OAuth] Status Code: \(http.statusCode)")
        print("🔑 [OAuth] Response Body: \(responseString)")
        if let responseHeaders = http.allHeaderFields as? [String: String] {
            print("🔑 [OAuth] Response Headers: \(responseHeaders)")
        }
        
        do {
            let tok = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            
            // Use expires_at timestamp if available, otherwise calculate from expires_in
            let expiresAt: Date?
            if let expiresAtString = tok.expires_at {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                expiresAt = formatter.date(from: expiresAtString) ?? Date().addingTimeInterval(TimeInterval(tok.expires_in))
            } else {
                expiresAt = Date().addingTimeInterval(TimeInterval(tok.expires_in))
            }
            
            print("🔑 [OAuth] Parsed Token Details:")
            print("🔑 [OAuth] - Token Type: \(tok.token_type)")
            print("🔑 [OAuth] - Expires In: \(tok.expires_in) seconds")
            print("🔑 [OAuth] - Scope: \(tok.scope ?? "none")")
            print("🔑 [OAuth] - Expires At (raw): \(tok.expires_at ?? "none")")
            if let expiresAt = expiresAt {
                print("🔑 [OAuth] - Expires At (parsed): \(expiresAt)")
            }
            
            return TokenResponse(
                accessToken: tok.access_token,
                tokenType: tok.token_type,
                expiresIn: tok.expires_in,
                scope: tok.scope,
                expiresAt: expiresAt
            )
        } catch {
            // Provide more specific error information
            if let decodingError = error as? DecodingError {
                let errorMessage = "JSON Decoding Error: \(decodingError.localizedDescription). Response: \(responseString)"
                print("🔑 [OAuth] Decoding Error: \(decodingError)")
                throw NSError(domain: "OAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                let errorMessage = "Token parsing failed: \(error.localizedDescription). Response: \(responseString)"
                print("🔑 [OAuth] Parsing Error: \(error)")
                throw NSError(domain: "OAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        }
    }
}

// MARK: - Consolidated PassportAPIService

/// Main service class for interacting with the Passport API.
/// Handles authentication, API requests, and response parsing.
/// Uses OAuth 2.0 for authentication and automatically manages token refresh.
final class PassportAPIService: ObservableObject {
    private let tokenManager: TokenManager
    private let session: URLSession
    private let clientTraceId: String
    /// Base URL for all Passport API endpoints
    private let baseURL: String
    
    init(config: OAuthConfiguration, session: URLSession = .shared, clientTraceId: String = "danko-test") {
        self.tokenManager = TokenManager(config: config, session: session)
        self.session = session
        self.clientTraceId = clientTraceId
        self.baseURL = config.baseURL
    }
    
    // MARK: - Public API Methods
    
    /// Get a valid access token (useful for testing)
    func getValidToken() async throws -> String {
        return try await tokenManager.validAccessToken()
    }
    
    /// Get full token response including scopes and expiration (useful for testing UI)
    func getTokenResponse() async throws -> TokenResponse {
        return try await tokenManager.getTokenResponse()
    }
    
    /// Debug method to test OAuth token endpoint and see raw response
    @MainActor
    func debugTokenEndpoint() async throws -> String {
        guard let productionCreds = try SecretsLoader.credentials(for: .production) else {
            throw NSError(domain: "Debug", code: -1, userInfo: [NSLocalizedDescriptionKey: "No production credentials found"])
        }
        let config = OAuthConfiguration(
            baseURL: "https://api.us.passportinc.com",
            tokenURL: URL(string: "https://api.us.passportinc.com/v3/shared/access-tokens")!,
            client_id: productionCreds.client_id,
            client_secret: productionCreds.client_secret,
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
    
    /// Fetches all parking zones for a given operator.
    /// API endpoint: GET /v3/shared/zones?operator_id={operator_id}
    /// Returns an array of Zone objects wrapped in a "data" field (standard API response format).
    func fetchZones(forOperatorId operatorId: String) async throws -> [Zone] {
        let url = URL(string: "\(baseURL)/v3/shared/zones?operator_id=\(operatorId.lowercased())")!
        print("🏢 Fetching zones for operator: \(operatorId)")
        print("🏢 URL: \(url.absoluteString)")
        
        // API returns zones wrapped in a "data" array: { "data": [Zone...] }
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
    
    /// Fetches parking rights (active parking permits) for a specific operator.
    /// API endpoint: GET /v4/enforcement/parking-rights?operator_id={id}&zone_id={id}&space_number={num}&vehicle_plate={plate}&vehicle_state={state}
    /// Parking rights represent vehicles that have permission to park in a zone.
    /// - Parameters:
    ///   - operatorId: Required operator ID
    ///   - zoneId: Optional zone ID (required if space_number is provided)
    ///   - spaceNumber: Optional space number
    ///   - vehiclePlate: Optional vehicle license plate
    ///   - vehicleState: Optional vehicle state (ISO 3166-2)
    func fetchParkingRights(
        forOperatorId operatorId: String,
        zoneId: String? = nil,
        spaceNumber: String? = nil,
        vehiclePlate: String? = nil,
        vehicleState: String? = nil
    ) async throws -> [ParkingRight] {
        // Build URL with query parameters using URLComponents for proper encoding
        var components = URLComponents(string: "\(baseURL)/v4/enforcement/parking-rights")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "operator_id", value: operatorId.lowercased())
        ]
        
        // Conditionally add zone_id if provided
        if let zoneId = zoneId, !zoneId.isEmpty {
            queryItems.append(URLQueryItem(name: "zone_id", value: zoneId))
        }
        
        // Conditionally add space/vehicle parameters if provided
        if let spaceNumber = spaceNumber, !spaceNumber.isEmpty {
            queryItems.append(URLQueryItem(name: "space_number", value: spaceNumber))
        }
        if let vehiclePlate = vehiclePlate, !vehiclePlate.isEmpty {
            queryItems.append(URLQueryItem(name: "vehicle_plate", value: vehiclePlate))
        }
        if let vehicleState = vehicleState, !vehicleState.isEmpty {
            queryItems.append(URLQueryItem(name: "vehicle_state", value: vehicleState))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct URL"])
        }
        
        var logParams = "operator_id=\(operatorId.lowercased())"
        if let zoneId = zoneId { logParams += ", zone_id=\(zoneId)" }
        if let spaceNumber = spaceNumber, !spaceNumber.isEmpty { logParams += ", space_number=\(spaceNumber)" }
        if let vehiclePlate = vehiclePlate, !vehiclePlate.isEmpty { logParams += ", vehicle_plate=\(vehiclePlate)" }
        if let vehicleState = vehicleState, !vehicleState.isEmpty { logParams += ", vehicle_state=\(vehicleState)" }
        
        print("🚗 Fetching parking rights for operator: \(operatorId)")
        print("🚗 URL: \(url.absoluteString)")
        print("🚗 Query parameters: \(logParams)")
        
        // Create a wrapper response model for the API
        struct ParkingRightsResponse: Codable {
            let data: [ParkingRight]
        }
        
        do {
            let response = try await performAuthenticatedRequest(url: url, responseType: ParkingRightsResponse.self)
            print("🚗 API returned \(response.data.count) parking rights")
            for (index, parkingRight) in response.data.enumerated() {
                print("🚗 Parking Right \(index + 1): ID=\(parkingRight.id), Vehicle=\(parkingRight.vehicle_plate ?? "N/A") (\(parkingRight.vehicle_state ?? "N/A")), Time=\(parkingRight.start_time) to \(parkingRight.end_time), Ref=\(parkingRight.reference_id ?? "N/A")")
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
    
    // MARK: - Parking Session Events API
    
    /// Publishes a parking session event to the Passport API.
    /// API endpoint: POST /v3/shared/events
    /// Events represent lifecycle changes: started, extended, or stopped.
    /// The API expects events wrapped in a standard format with type, version, and data array.
    func publishParkingSessionEvent<T: Encodable>(
        type: String,
        version: String = "1.0.0",
        data: [T]
    ) async throws -> Bool {
        let url = URL(string: "\(baseURL)/v3/shared/events")!
        print("🎯 Publishing parking session event: \(type)")
        
        // Build event payload matching API schema: { type, version, data: [...] }
        let requestBody: [String: Any] = [
            "type": type,
            "version": version,
            "data": try data.map { item -> [String: Any] in
                // Convert Encodable struct to dictionary for JSON serialization
                let jsonData = try JSONEncoder().encode(item)
                return try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            }
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Log the request body
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🎯 Request body: \(jsonString)")
        }
        
        var request = try await createAuthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let (data, response) = try await performRequest(request)
        
        // Log response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🎯 Response: \(responseString)")
        }
        
        return (200..<300).contains(response.statusCode)
    }
    
    // MARK: - Private Network Methods
    
    /// Performs an authenticated GET request and decodes the JSON response.
    /// Automatically adds Bearer token to Authorization header.
    /// Uses snake_case to camelCase conversion for Swift naming conventions.
    private func performAuthenticatedRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        let request = try await createAuthenticatedRequest(url: url)
        let (data, _) = try await performRequest(request)
        
        // Configure decoder to convert API's snake_case keys to Swift's camelCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let result = try decoder.decode(responseType, from: data)
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
    
    /// Creates an authenticated URLRequest with OAuth Bearer token.
    /// Adds Authorization header with "Bearer {token}" format (OAuth 2.0 standard).
    /// Also includes client trace ID header for API debugging/tracking.
    private func createAuthenticatedRequest(url: URL, method: String = "GET") async throws -> URLRequest {
        let token = try await tokenManager.validAccessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        // OAuth 2.0 standard: Bearer token in Authorization header
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
        
        // Handle 401 Unauthorized: token may have expired, retry with fresh token
        if httpResponse.statusCode == 401 {
            // Token expired, invalidate cached token and fetch a new one
            await tokenManager.invalidate()
            let newToken = try await tokenManager.validAccessToken()
            // Retry the request with the new token (automatic retry logic)
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
