import Foundation
import MuseeCore
import MuseeDomain

/// Normalizes data from heterogeneous sources into unified muse format
public class SourceNormalizer {
    
    /// Unified normalized muse data
    public struct NormalizedMuseData: Sendable {
        public let person: Person
        public let biographicalClaims: [BiographicalClaim]
        public let mediaAssets: [MediaAsset]
        public let sourceMetadata: [String: SourceMetadata]
        public let confidence: Double
        public let normalizedAt: Date
        
        public init(
            person: Person,
            biographicalClaims: [BiographicalClaim],
            mediaAssets: [MediaAsset],
            sourceMetadata: [String: SourceMetadata],
            confidence: Double,
            normalizedAt: Date = Date()
        ) {
            self.person = person
            self.biographicalClaims = biographicalClaims
            self.mediaAssets = mediaAssets
            self.sourceMetadata = sourceMetadata
            self.confidence = confidence
            self.normalizedAt = normalizedAt
        }
    }
    
    /// Metadata about data sources
    public struct SourceMetadata: Sendable {
        public let sourceType: String
        public let sourceURL: URL?
        public let retrievedAt: Date
        public let reliability: Double // 0.0 to 1.0
        public let dataQuality: Double // 0.0 to 1.0
        
        public init(sourceType: String, sourceURL: URL?, retrievedAt: Date, reliability: Double, dataQuality: Double) {
            self.sourceType = sourceType
            self.sourceURL = sourceURL
            self.retrievedAt = retrievedAt
            self.reliability = reliability
            self.dataQuality = dataQuality
        }
    }
    
    /// Normalization result with any issues encountered
    public struct NormalizationResult: Sendable {
        public let data: NormalizedMuseData
        public let warnings: [NormalizationWarning]
        public let conflicts: [DataConflict]
        
        public init(data: NormalizedMuseData, warnings: [NormalizationWarning], conflicts: [DataConflict]) {
            self.data = data
            self.warnings = warnings
            self.conflicts = conflicts
        }
    }
    
    /// Warning about data normalization
    public enum NormalizationWarning: Sendable {
        case missingData(String)
        case lowConfidence(String, Double)
        case inconsistentData(String)
        case deprecatedSource(String)
    }
    
    /// Conflict between data sources
    public struct DataConflict: Sendable {
        public let field: String
        public let conflictingValues: [String] // Simplified to strings for Sendable
        public let sources: [String]
        public let resolution: ConflictResolution

        public enum ConflictResolution: Sendable {
            case keepFirst
            case keepHighestConfidence
            case merge
            case rejectAll
        }
    }
    
    private let stableIDGenerator: () -> StableID
    
    public init(stableIDGenerator: @escaping () -> StableID = { StableID(UUID().uuidString) }) {
        self.stableIDGenerator = stableIDGenerator
    }
    
    /// Normalize data from multiple sources into unified format
    public func normalize(
        scrapedData: MuseData,
        socialData: [SocialMediaData]? = nil,
        sourceReliability: [String: Double] = [:]
    ) async -> NormalizationResult {

        var warnings: [NormalizationWarning] = []
        var conflicts: [DataConflict] = []

        // Create base person from scraped data
        let person = createPerson(from: scrapedData)

        // Generate biographical claims from all sources
        var claims = [BiographicalClaim]()
        var mediaAssets = [MediaAsset]()
        var sourceMetadata = [String: SourceMetadata]()

        // Claims from web scraping
        claims.append(contentsOf: claimsFromScrapedData(scrapedData))

        // Claims from social media
        if let social = socialData {
            for (index, socialData) in social.enumerated() {
                let (socialClaims, socialAssets) = claimsFromSocialData(socialData, sourceIndex: index)
                claims.append(contentsOf: socialClaims)
                mediaAssets.append(contentsOf: socialAssets)
            }
        }

        // Create source metadata
        sourceMetadata["web_scraping"] = SourceMetadata(
            sourceType: "web_scraping",
            sourceURL: nil,
            retrievedAt: Date(),
            reliability: sourceReliability["web"] ?? 0.7,
            dataQuality: 0.8
        )

        if socialData != nil {
            sourceMetadata["social_media"] = SourceMetadata(
                sourceType: "social_media",
                sourceURL: nil,
                retrievedAt: Date(),
                reliability: sourceReliability["social"] ?? 0.6,
                dataQuality: 0.7
            )
        }

        // Resolve conflicts in claims (simplified)
        let resolvedClaims = resolveClaimConflicts(claims)

        // Calculate overall confidence
        let confidence = calculateOverallConfidence(
            claims: resolvedClaims,
            sourceMetadata: sourceMetadata
        )

        let normalizedData = NormalizedMuseData(
            person: person,
            biographicalClaims: resolvedClaims,
            mediaAssets: mediaAssets,
            sourceMetadata: sourceMetadata,
            confidence: confidence
        )

        return NormalizationResult(
            data: normalizedData,
            warnings: warnings,
            conflicts: conflicts
        )
    }
    
    private func createPerson(from scrapedData: MuseeScraper.MuseData) -> Person {
        let id = stableIDGenerator()
        let displayName = scrapedData.name
        
        // Extract aliases from metadata if available
        let aliases: Set<String> = {
            if let aliasesStr = scrapedData.metadata["aliases"] as? String {
                return Set(aliasesStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
            }
            return []
        }()
        
        // Convert social accounts to platform handles
        let handles: Set<PlatformHandle> = Set(
            scrapedData.socialAccounts.map { account in
                let platform = Platform(rawValue: account.platform) ?? .website
                return PlatformHandle(platform: platform, handle: account.username)
            }
        )
        
        return Person(
            id: id,
            displayName: displayName,
            aliases: aliases,
            handles: handles,
            tags: [] // Would be populated from categorization
        )
    }
    
    private func claimsFromScrapedData(_ data: MuseeScraper.MuseData) -> [BiographicalClaim] {
        var claims = [BiographicalClaim]()
        let subjectId = stableIDGenerator()
        
        // Name claim
        claims.append(BiographicalClaim(
            id: stableIDGenerator(),
            subject: subjectId,
            property: .note,
            value: .string("Name: \(data.name)"),
            confidence: .high,
            references: []
        ))
        
        // Bio claim
        if let bio = data.bio {
            claims.append(BiographicalClaim(
                id: stableIDGenerator(),
                subject: subjectId,
                property: .note,
                value: .string("Bio: \(bio)"),
                confidence: .medium,
                references: []
            ))
        }
        
        // Social media accounts (basic info)
        for account in data.socialAccounts {
            claims.append(BiographicalClaim(
                id: stableIDGenerator(),
                subject: subjectId,
                property: .note,
                value: .string("Social account: \(account.platform) - @\(account.username)"),
                confidence: .medium,
                references: []
            ))
        }
        
        return claims
    }
    
    private func claimsFromSocialData(_ data: MuseeScraper.SocialMediaData, sourceIndex: Int) -> ([BiographicalClaim], [MediaAsset]) {
        var claims = [BiographicalClaim]()
        var assets = [MediaAsset]()
        let subjectId = stableIDGenerator()
        
        // Platform-specific claims
        if let followerCount = data.followerCount {
            claims.append(BiographicalClaim(
                id: stableIDGenerator(),
                subject: subjectId,
                property: .note,
                value: .string("\(data.platform.rawValue) followers: \(followerCount)"),
                confidence: .medium,
                references: []
            ))
        }
        
        if let bio = data.bio {
            claims.append(BiographicalClaim(
                id: stableIDGenerator(),
                subject: subjectId,
                property: .note,
                value: .string("\(data.platform.rawValue) bio: \(bio)"),
                confidence: .medium,
                references: []
            ))
        }
        
        // Convert posts to media assets
        for post in data.posts {
            if let mediaURL = post.mediaURLs.first {
                let asset = MediaAsset(
                    id: stableIDGenerator(),
                    sha256: "", // Would be computed from actual file
                    kind: .image,
                    originalFilename: "\(data.platform.rawValue)_\(post.id)",
                    originalSourceURL: mediaURL,
                    capturedAt: nil
                )
                assets.append(asset)
            }
        }
        
        return (claims, assets)
    }
    

    
    private func resolveClaimConflicts(_ claims: [BiographicalClaim]) -> [BiographicalClaim] {
        // Simplified: just return all claims (no conflict resolution for now)
        return claims
    }
    
    private func calculateOverallConfidence(
        claims: [BiographicalClaim],
        sourceMetadata: [String: SourceMetadata]
    ) -> Double {
        // Base confidence from claims
        let claimConfidence = claims.isEmpty ? 0.0 : claims.map { confidenceToDouble($0.confidence) }.reduce(0, +) / Double(claims.count)

        // Source reliability factor
        let sourceConfidence = sourceMetadata.isEmpty ? 0.0 : sourceMetadata.values.map { $0.reliability }.reduce(0, +) / Double(sourceMetadata.count)

        return max(0.0, min(1.0, claimConfidence * 0.6 + sourceConfidence * 0.4))
    }

    private func confidenceToDouble(_ confidence: ConfidenceLevel) -> Double {
        switch confidence {
        case .verified: return 1.0
        case .high: return 0.8
        case .medium: return 0.6
        case .low: return 0.4
        case .unverified: return 0.2
        }
    }
}