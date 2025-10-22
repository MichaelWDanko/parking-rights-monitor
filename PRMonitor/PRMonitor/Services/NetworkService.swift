//
//  NetworkService.swift
//  PRMonitor
//
//  Created by Michael Danko on 10/21/25.
//
import Foundation

struct OAuthConfiguration {
    let tokenURL: URL
    let client_id: String
    let client_secret: String
    let scope: String
    let audience: String
}
