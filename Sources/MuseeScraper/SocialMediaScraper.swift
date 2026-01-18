import Foundation

/// Protocol for social media platform scrapers
public protocol SocialMediaScraper {
    /// The social media platform this scraper handles
    var platform: SocialPlatform { get }
    
    /// Scrape content for a given username/handle
    func scrapeContent(for username: String) async throws -> SocialMediaData
    
    /// Scrape content from a specific URL
    func scrapeContent(from url: URL) async throws -> SocialMediaData
}

/// Supported social media platforms
public enum SocialPlatform: String, Sendable {
    case instagram = "Instagram"
    case tiktok = "TikTok" 
    case youtube = "YouTube"
    case twitter = "Twitter/X"
    
    /// Base URL for the platform
    var baseURL: URL {
        switch self {
        case .instagram: return URL(string: "https://www.instagram.com")!
        case .tiktok: return URL(string: "https://www.tiktok.com")!
        case .youtube: return URL(string: "https://www.youtube.com")!
        case .twitter: return URL(string: "https://twitter.com")!
        }
    }
}

/// Unified data structure for social media content
public struct SocialMediaData: Sendable {
    public let platform: SocialPlatform
    public let username: String
    public let profileURL: URL
    public let bio: String?
    public let followerCount: Int?
    public let posts: [SocialPost]
    public let mediaURLs: [URL]
    public let metadata: [String: String]
    
    public init(platform: SocialPlatform, username: String, profileURL: URL, bio: String?, followerCount: Int?, posts: [SocialPost], mediaURLs: [URL], metadata: [String: String]) {
        self.platform = platform
        self.username = username
        self.profileURL = profileURL
        self.bio = bio
        self.followerCount = followerCount
        self.posts = posts
        self.mediaURLs = mediaURLs
        self.metadata = metadata
    }
}

/// Individual social media post
public struct SocialPost: Sendable {
    public let id: String
    public let url: URL
    public let caption: String?
    public let timestamp: Date?
    public let likes: Int?
    public let comments: Int?
    public let mediaURLs: [URL]
    
    public init(id: String, url: URL, caption: String?, timestamp: Date?, likes: Int?, comments: Int?, mediaURLs: [URL]) {
        self.id = id
        self.url = url
        self.caption = caption
        self.timestamp = timestamp
        self.likes = likes
        self.comments = comments
        self.mediaURLs = mediaURLs
    }
}