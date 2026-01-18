import Foundation
import MuseeCore

/// Orchestrator for coordinating multiple social media scrapers
public class SocialMediaOrchestrator {
    private let scrapers: [SocialPlatform: SocialMediaScraper]
    
    public init() {
        self.scrapers = [
            .instagram: InstagramScraper(),
            .tiktok: TikTokScraper(),
            .youtube: YouTubeScraper(),
            .twitter: TwitterScraper()
        ]
    }
    
    /// Initialize with custom scrapers
    public init(scrapers: [SocialPlatform: SocialMediaScraper]) {
        self.scrapers = scrapers
    }
    
    /// Scrape from multiple social platforms for a username
    public func scrapeAllPlatforms(for username: String) async throws -> [SocialMediaData] {
        var results: [SocialMediaData] = []
        
        for (_, scraper) in scrapers {
            let result = try await scraper.scrapeContent(for: username)
            results.append(result)
        }
        
        return results
    }
    
    /// Scrape from a specific platform and username
    public func scrape(platform: SocialPlatform, username: String) async throws -> SocialMediaData {
        guard let scraper = scrapers[platform] else {
            throw MuseeError.invalidArgument("Unsupported platform: \(platform.rawValue)")
        }
        
        return try await scraper.scrapeContent(for: username)
    }
    
    /// Scrape from a social media URL (auto-detects platform)
    public func scrape(from url: URL) async throws -> SocialMediaData {
        let platform = try detectPlatform(from: url)
        guard let scraper = scrapers[platform] else {
            throw MuseeError.invalidArgument("Unsupported platform: \(platform.rawValue)")
        }
        
        return try await scraper.scrapeContent(from: url)
    }
    
    /// Detect social media platform from URL
    private func detectPlatform(from url: URL) throws -> SocialPlatform {
        let host = url.host?.lowercased() ?? ""
        
        if host.contains("instagram.com") {
            return .instagram
        } else if host.contains("tiktok.com") {
            return .tiktok
        } else if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        } else if host.contains("twitter.com") || host.contains("x.com") {
            return .twitter
        } else {
            throw MuseeError.invalidArgument("Unable to detect social platform from URL: \(url)")
        }
    }
    
    /// Get available platforms
    public var availablePlatforms: [SocialPlatform] {
        Array(scrapers.keys)
    }
}