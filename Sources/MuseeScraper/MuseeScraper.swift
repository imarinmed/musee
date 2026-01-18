import Foundation
import MuseeCore

/// Protocol for web scrapers that extract muse data from various sources
public protocol WebScraper {
    /// Scrapes data from a given URL and returns structured muse information
    func scrape(from url: URL) async throws -> MuseData
    
    /// Scrapes data from multiple URLs concurrently
    func scrape(from urls: [URL]) async throws -> [MuseData]
}

/// Structured data extracted from web scraping
public struct MuseData: Sendable {
    public let name: String
    public let bio: String?
    public let socialAccounts: [SocialAccount]
    public let mediaURLs: [URL]
    public let metadata: [String: String]
    
    public init(name: String, bio: String?, socialAccounts: [SocialAccount], mediaURLs: [URL], metadata: [String: String]) {
        self.name = name
        self.bio = bio
        self.socialAccounts = socialAccounts
        self.mediaURLs = mediaURLs
        self.metadata = metadata
    }
}

public struct SocialAccount: Sendable {
    public let platform: String
    public let username: String
    public let url: URL
    
    public init(platform: String, username: String, url: URL) {
        self.platform = platform
        self.username = username
        self.url = url
    }
}