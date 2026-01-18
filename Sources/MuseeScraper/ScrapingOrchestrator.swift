import Foundation
import MuseeCore
import MuseeDomain

/// Comprehensive orchestrator for multi-source muse data scraping
public class ScrapingOrchestrator {
    
    /// Scraping configuration
    public struct Configuration: Sendable {
        public let enableWebScraping: Bool
        public let enableSocialMedia: Bool
        public let enableImageAnalysis: Bool
        public let maxConcurrentRequests: Int
        public let requestTimeout: TimeInterval
        public let retryAttempts: Int
        
        public static let standard = Configuration(
            enableWebScraping: true,
            enableSocialMedia: true,
            enableImageAnalysis: true,
            maxConcurrentRequests: 5,
            requestTimeout: 30.0,
            retryAttempts: 3
        )
        
        public init(
            enableWebScraping: Bool = true,
            enableSocialMedia: Bool = true,
            enableImageAnalysis: Bool = true,
            maxConcurrentRequests: Int = 5,
            requestTimeout: TimeInterval = 30.0,
            retryAttempts: Int = 3
        ) {
            self.enableWebScraping = enableWebScraping
            self.enableSocialMedia = enableSocialMedia
            self.enableImageAnalysis = enableImageAnalysis
            self.maxConcurrentRequests = maxConcurrentRequests
            self.requestTimeout = requestTimeout
            self.retryAttempts = retryAttempts
        }
    }
    
    /// Comprehensive scraping result
    public struct ScrapingResult: Sendable {
        public let museName: String
        public let webData: MuseData?
        public let socialData: [SocialMediaData]
        public let imageCharacteristics: [String: String]? // Simplified to strings
        public let aggregatedData: MuseData?
        public let errors: [ScrapingError]
        public let scrapingDuration: TimeInterval
        public let sourcesAttempted: Int
        public let sourcesSuccessful: Int
        
        public init(
            museName: String,
            webData: MuseData?,
            socialData: [SocialMediaData],
            imageCharacteristics: [String: String]?,
            aggregatedData: MuseData?,
            errors: [ScrapingError],
            scrapingDuration: TimeInterval,
            sourcesAttempted: Int,
            sourcesSuccessful: Int
        ) {
            self.museName = museName
            self.webData = webData
            self.socialData = socialData
            self.imageCharacteristics = imageCharacteristics
            self.aggregatedData = aggregatedData
            self.errors = errors
            self.scrapingDuration = scrapingDuration
            self.sourcesAttempted = sourcesAttempted
            self.sourcesSuccessful = sourcesSuccessful
        }
        
        public var successRate: Double {
            sourcesAttempted > 0 ? Double(sourcesSuccessful) / Double(sourcesAttempted) : 0.0
        }
        
        public var hasErrors: Bool {
            !errors.isEmpty
        }
    }
    
    /// Scraping error with context
    public struct ScrapingError: Sendable {
        public let source: String
        public let error: Error
        public let timestamp: Date
        
        public init(source: String, error: Error, timestamp: Date = Date()) {
            self.source = source
            self.error = error
            self.timestamp = timestamp
        }
    }
    
    private let configuration: Configuration
    private let webScraper: AIWebScraper
    private let socialOrchestrator: SocialMediaOrchestrator
    private let normalizer: SourceNormalizer
    
    public init(
        configuration: Configuration = .standard,
        webScraper: AIWebScraper? = nil,
        socialOrchestrator: SocialMediaOrchestrator? = nil,
        normalizer: SourceNormalizer? = nil
    ) {
        self.configuration = configuration
        self.webScraper = webScraper ?? AIWebScraper()
        self.socialOrchestrator = socialOrchestrator ?? SocialMediaOrchestrator()
        self.normalizer = normalizer ?? SourceNormalizer()
    }
    
    /// Comprehensive scraping for a muse by name
    public func scrapeMuse(byName name: String) async -> ScrapingResult {
        let startTime = Date()
        var errors: [ScrapingError] = []
        var sourcesAttempted = 0
        var sourcesSuccessful = 0
        
        // Sequential scraping for now to avoid self capture issues
        // TODO: Implement proper parallel scraping with isolated functions
        let webResult = configuration.enableWebScraping ? await scrapeWebData(for: name) : nil
        let socialResult = configuration.enableSocialMedia ? await scrapeSocialData(for: name) : nil
        let imageResult = configuration.enableImageAnalysis ? await scrapeImageData(for: name) : nil
        
        // Process web scraping result
        var webData: MuseData?
        if let webRes = webResult {
            sourcesAttempted += 1
            switch webRes {
            case .success(let data):
                webData = data
                sourcesSuccessful += 1
            case .failure(let error):
                errors.append(ScrapingError(source: "web", error: error))
            }
        }
        
        // Process social media result
        var socialData: [SocialMediaData] = []
        if let socialRes = socialResult {
            sourcesAttempted += 1
            switch socialRes {
            case .success(let data):
                socialData = data
                sourcesSuccessful += 1
            case .failure(let error):
                errors.append(ScrapingError(source: "social", error: error))
            }
        }
        
        // Process image analysis result
        var imageCharacteristics: [String: String]?
        if let imageRes = imageResult {
            sourcesAttempted += 1
            switch imageRes {
            case .success(let chars):
                imageCharacteristics = chars
                sourcesSuccessful += 1
            case .failure(let error):
                errors.append(ScrapingError(source: "image", error: error))
            }
        }
        
        // Aggregate and normalize data
        var aggregatedData: MuseData?
        if let web = webData {
            do {
                let result = try await normalizer.normalize(
                    scrapedData: web,
                    socialData: socialData.isEmpty ? nil : socialData,
                    sourceReliability: [
                        "web": 0.7,
                        "social": 0.6,
                        "image": 0.8
                    ]
                )
                // Create aggregated muse data from normalized results
                let bioClaim = result.data.biographicalClaims.first { $0.property == .note }
                let bioText = bioClaim?.value.description ?? "No bio available"

                let socialAccounts = result.data.person.handles.map { account in
                    SocialAccount(
                        platform: account.platform.rawValue,
                        username: account.handle,
                        url: URL(string: "https://\(account.platform.rawValue).com/\(account.handle)")!
                    )
                }

                let mediaURLs = result.data.mediaAssets.compactMap { $0.originalSourceURL }

                aggregatedData = MuseData(
                    name: result.data.person.displayName,
                    bio: bioText,
                    socialAccounts: socialAccounts,
                    mediaURLs: mediaURLs,
                    metadata: [:]
                )
            } catch {
                errors.append(ScrapingError(source: "normalization", error: error))
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return ScrapingResult(
            museName: name,
            webData: webData,
            socialData: socialData,
            imageCharacteristics: imageCharacteristics,
            aggregatedData: aggregatedData,
            errors: errors,
            scrapingDuration: duration,
            sourcesAttempted: sourcesAttempted,
            sourcesSuccessful: sourcesSuccessful
        )
    }
    
    /// Scrape from a specific URL
    public func scrapeMuse(from url: URL) async -> ScrapingResult {
        let startTime = Date()
        var errors: [ScrapingError] = []
        
        // Try web scraping first
        let webResult = await scrapeWebData(from: url)
        var webData: MuseData?
        var museName = "Unknown"
        
        switch webResult {
        case .success(let data):
            webData = data
            museName = data.name ?? "Unknown"
        case .failure(let error):
            errors.append(ScrapingError(source: "web", error: error))
        }
        
        // Try social media if URL matches
        var socialData: [SocialMediaData] = []
        if configuration.enableSocialMedia {
            let socialResult = await scrapeSocialData(from: url)
            switch socialResult {
            case .success(let data):
                socialData = data
                if museName == "Unknown", let firstSocial = data.first {
                    museName = firstSocial.username
                }
            case .failure(let error):
                errors.append(ScrapingError(source: "social", error: error))
            }
        }
        
        // Try image analysis if URL is an image
        var imageCharacteristics: [String: String]?
        if configuration.enableImageAnalysis, isImageURL(url) {
            let imageResult = await scrapeImageData(from: url)
            switch imageResult {
            case .success(let chars):
                imageCharacteristics = chars
            case .failure(let error):
                errors.append(ScrapingError(source: "image", error: error))
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return ScrapingResult(
            museName: museName,
            webData: webData,
            socialData: socialData,
            imageCharacteristics: imageCharacteristics,
            aggregatedData: nil, // Would need more complex aggregation
            errors: errors,
            scrapingDuration: duration,
            sourcesAttempted: errors.count + (webData != nil ? 1 : 0) + socialData.count + (imageCharacteristics != nil ? 1 : 0),
            sourcesSuccessful: (webData != nil ? 1 : 0) + socialData.count + (imageCharacteristics != nil ? 1 : 0)
        )
    }
    
    // MARK: - Private Methods
    
    private func scrapeWebData(for name: String) async -> Result<MuseData, Error> {
        // For now, simulate web scraping
        // In real implementation, this would search for the muse online
        let mockData = MuseData(
            name: name,
            bio: "Mock bio for \(name) from web scraping",
            socialAccounts: [],
            mediaURLs: [],
            metadata: ["source": "web_mock"]
        )
        return .success(mockData)
    }
    
    private func scrapeWebData(from url: URL) async -> Result<MuseData, Error> {
        do {
            let data = try await webScraper.scrape(from: url)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    private func scrapeSocialData(for name: String) async -> Result<[SocialMediaData], Error> {
        do {
            let data = try await socialOrchestrator.scrapeAllPlatforms(for: name)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    private func scrapeSocialData(from url: URL) async -> Result<[SocialMediaData], Error> {
        do {
            let data = try await socialOrchestrator.scrape(from: url)
            return .success([data])
        } catch {
            return .failure(error)
        }
    }
    
    private func scrapeImageData(for name: String) async -> Result<[String: String], Error> {
        // For now, return mock image characteristics
        let mockCharacteristics: [String: String] = [
            "estimatedHeight": "170.0",
            "bodyMeasurements": "bust:90.0,waist:65.0,hips:95.0",
            "hairColor": "brown",
            "eyeColor": "brown",
            "confidence": "0.75"
        ]
        return .success(mockCharacteristics)
    }
    
    private func scrapeImageData(from url: URL) async -> Result<[String: String], Error> {
        // In real implementation, would download and analyze the image
        // For now, return mock data
        let mockCharacteristics: [String: String] = [
            "imageURL": url.absoluteString,
            "analyzed": "true",
            "confidence": "0.8"
        ]
        return .success(mockCharacteristics)
    }
    
    private func isImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp"]
        let pathExtension = url.pathExtension.lowercased()
        return imageExtensions.contains(pathExtension)
    }
}

/// Extension to provide string value from claim value
private extension ClaimValue {
    var description: String {
        switch self {
        case .string(let value): return value
        case .number(let value): return String(value)
        case .person(let id): return "Person: \(id)"
        case .media(let id): return "Media: \(id)"
        }
    }
}