//
//  PreviewEnvironment.swift
//  Passport API Explorer
//
//  Created by Assistant on 10/31/25.
//

import Foundation

enum PreviewEnvironment {
    static func makePreviewService() -> PassportAPIService {
        let config = OAuthConfiguration(
            tokenURL: URL(string: "https://example.com/token")!,
            client_id: "test",
            client_secret: "test",
            audience: "preview",
            clientTraceId: "preview"
        )
        return PassportAPIService(config: config)
    }
}


