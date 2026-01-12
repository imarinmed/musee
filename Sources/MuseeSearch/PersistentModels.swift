import Foundation
import SwiftData

@Model
public class PersistentMediaAsset {
    @Attribute(.unique) public var id: String
    public var sha256: String
    public var kind: String  // Store as string for simplicity
    public var originalFilename: String?
    public var capturedAtYear: Int?
    public var capturedAtMonth: Int?
    public var capturedAtDay: Int?

    public init(id: String, sha256: String, kind: String, originalFilename: String?, capturedAtYear: Int?, capturedAtMonth: Int?, capturedAtDay: Int?) {
        self.id = id
        self.sha256 = sha256
        self.kind = kind
        self.originalFilename = originalFilename
        self.capturedAtYear = capturedAtYear
        self.capturedAtMonth = capturedAtMonth
        self.capturedAtDay = capturedAtDay
    }
}

@Model
public class PersistentTag {
    @Attribute(.unique) public var value: String
    public var namespace: String

    public init(value: String, namespace: String) {
        self.value = value
        self.namespace = namespace
    }
}

@Model
public class SmartCollectionModel {
    @Attribute(.unique) public var id: String
    public var name: String
    public var descriptionText: String?
    public var rulesData: Data  // JSON encoded rules
    public var sortOptionsData: Data  // JSON encoded sort options

    public init(id: String, name: String, descriptionText: String?, rulesData: Data, sortOptionsData: Data) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.rulesData = rulesData
        self.sortOptionsData = sortOptionsData
    }
}

@Model
public class PersistentBeautyAnalysis {
    @Attribute(.unique) public var id: String
    public var assetId: String  // Reference to PersistentMediaAsset
    public var analysisDate: Date
    public var beautyFeaturesData: Data  // JSON encoded BeautyFeatures

    // Core beauty scores for quick queries
    public var overallScore: Double
    public var facialRatioScore: Double
    public var symmetryScore: Double
    public var skinQualityScore: Double

    // Demographic analysis (if available)
    public var estimatedAge: Int?
    public var estimatedGender: String?
    public var ethnicityAnalysis: String?

    public init(
        id: String,
        assetId: String,
        analysisDate: Date,
        beautyFeaturesData: Data,
        overallScore: Double,
        facialRatioScore: Double,
        symmetryScore: Double,
        skinQualityScore: Double,
        estimatedAge: Int? = nil,
        estimatedGender: String? = nil,
        ethnicityAnalysis: String? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.analysisDate = analysisDate
        self.beautyFeaturesData = beautyFeaturesData
        self.overallScore = overallScore
        self.facialRatioScore = facialRatioScore
        self.symmetryScore = symmetryScore
        self.skinQualityScore = skinQualityScore
        self.estimatedAge = estimatedAge
        self.estimatedGender = estimatedGender
        self.ethnicityAnalysis = ethnicityAnalysis
    }
}

@Model
public class UserCollection {
    @Attribute(.unique) public var id: String
    public var name: String
    public var descriptionText: String?
    public var createdDate: Date
    public var lastModified: Date
    public var isFavorite: Bool

    // Collection metadata
    public var theme: String?  // e.g., "fitness", "portrait", "cultural"
    public var tags: [String]  // User-defined tags

    public init(
        id: String,
        name: String,
        descriptionText: String?,
        createdDate: Date,
        lastModified: Date,
        isFavorite: Bool = false,
        theme: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.isFavorite = isFavorite
        self.theme = theme
        self.tags = tags
    }
}

@Model
public class CollectionAsset {
    @Attribute(.unique) public var id: String
    public var collectionId: String  // Reference to UserCollection
    public var assetId: String       // Reference to PersistentMediaAsset
    public var addedDate: Date
    public var notes: String?        // User notes about this asset in collection

    // User's personal ratings
    public var userRating: Int?      // 1-5 stars
    public var isFavorite: Bool

    public init(
        id: String,
        collectionId: String,
        assetId: String,
        addedDate: Date,
        notes: String? = nil,
        userRating: Int? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.collectionId = collectionId
        self.assetId = assetId
        self.addedDate = addedDate
        self.notes = notes
        self.userRating = userRating
        self.isFavorite = isFavorite
    }
}

@Model
public class BeautyTrend {
    @Attribute(.unique) public var id: String
    public var userId: String  // For multi-user support
    public var date: Date
    public var trendType: String  // e.g., "overall_beauty", "skin_quality"

    // Trend data
    public var averageScore: Double
    public var scoreChange: Double  // Change from previous period
    public var dataPoints: Int

    // Analysis period
    public var periodStart: Date
    public var periodEnd: Date

    public init(
        id: String,
        userId: String,
        date: Date,
        trendType: String,
        averageScore: Double,
        scoreChange: Double,
        dataPoints: Int,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.trendType = trendType
        self.averageScore = averageScore
        self.scoreChange = scoreChange
        self.dataPoints = dataPoints
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }
}
