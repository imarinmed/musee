import Foundation
import SwiftData
import MuseeCore
import MuseeDomain
import MuseeVision

/// Service for managing persistent data using SwiftData.
public actor PersistenceService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init?() {
        do {
            let schema = Schema([
                PersistentMediaAsset.self,
                PersistentTag.self,
                SmartCollectionModel.self,
                PersistentBeautyAnalysis.self,
                UserCollection.self,
                CollectionAsset.self,
                BeautyTrend.self
            ])

            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            print("Failed to initialize persistence service: \(error)")
            return nil
        }
    }

    // MARK: - Beauty Analysis Persistence

    /// Saves beauty analysis results for an asset.
    public func saveBeautyAnalysis(_ analysis: BeautyFeatures, for assetId: StableID) async throws {
        let encoder = JSONEncoder()
        let beautyData = try encoder.encode(analysis)

        let persistentAnalysis = PersistentBeautyAnalysis(
            id: UUID().uuidString,
            assetId: assetId.rawValue,
            analysisDate: Date(),
            beautyFeaturesData: beautyData,
            overallScore: analysis.facialRatios.overallScore,
            facialRatioScore: analysis.facialRatios.goldenRatioScore,
            symmetryScore: analysis.symmetry.overallScore,
            skinQualityScore: analysis.skinAnalysis.overallQuality
        )

        modelContext.insert(persistentAnalysis)
        try modelContext.save()
    }

    /// Retrieves beauty analysis for an asset.
    public func getBeautyAnalysis(for assetId: StableID) async throws -> BeautyFeatures? {
        let descriptor = FetchDescriptor<PersistentBeautyAnalysis>(
            predicate: #Predicate { $0.assetId == assetId.rawValue },
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )

        guard let analysis = try modelContext.fetch(descriptor).first else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(BeautyFeatures.self, from: analysis.beautyFeaturesData)
    }

    // MARK: - Asset Management

    /// Saves or updates a media asset.
    public func saveAsset(_ asset: MediaAsset) async throws {
        // Check if asset already exists
        let existingAssets = try modelContext.fetch(
            FetchDescriptor<PersistentMediaAsset>(
                predicate: #Predicate { $0.id == asset.id.rawValue }
            )
        )

        let persistentAsset: PersistentMediaAsset
        if let existing = existingAssets.first {
            persistentAsset = existing
            // Update existing asset
            persistentAsset.sha256 = asset.sha256
            persistentAsset.kind = asset.kind.rawValue
            persistentAsset.originalFilename = asset.originalFilename
            persistentAsset.capturedAtYear = asset.capturedAt?.year
            persistentAsset.capturedAtMonth = asset.capturedAt?.month
            persistentAsset.capturedAtDay = asset.capturedAt?.day
        } else {
            // Create new asset
            persistentAsset = PersistentMediaAsset(
                id: asset.id.rawValue,
                sha256: asset.sha256,
                kind: asset.kind.rawValue,
                originalFilename: asset.originalFilename,
                capturedAtYear: asset.capturedAt?.year,
                capturedAtMonth: asset.capturedAt?.month,
                capturedAtDay: asset.capturedAt?.day
            )
            modelContext.insert(persistentAsset)
        }

        try modelContext.save()
    }

    /// Retrieves all persisted assets.
    public func getAllAssets() async throws -> [MediaAsset] {
        let persistentAssets = try modelContext.fetch(
            FetchDescriptor<PersistentMediaAsset>()
        )

        return persistentAssets.map { persistent in
            var capturedAt: PartialDate?
            if let year = persistent.capturedAtYear {
                if let month = persistent.capturedAtMonth, let day = persistent.capturedAtDay {
                    capturedAt = PartialDate.day(year: year, month: month, day: day)
                } else if let month = persistent.capturedAtMonth {
                    capturedAt = PartialDate.month(year: year, month: month)
                } else {
                    capturedAt = PartialDate.year(year)
                }
            }

            return MediaAsset(
                id: StableID(persistent.id),
                sha256: persistent.sha256,
                kind: MediaKind(rawValue: persistent.kind) ?? .image,
                originalFilename: persistent.originalFilename,
                capturedAt: capturedAt
            )
        }
    }

    // MARK: - Collection Management

    /// Creates a new user collection.
    public func createCollection(name: String, description: String? = nil, theme: String? = nil) async throws -> UserCollection {
        let collection = UserCollection(
            id: UUID().uuidString,
            name: name,
            descriptionText: description,
            createdDate: Date(),
            lastModified: Date(),
            theme: theme
        )

        modelContext.insert(collection)
        try modelContext.save()

        return collection
    }

    /// Adds an asset to a collection.
    public func addAssetToCollection(assetId: StableID, collectionId: String, notes: String? = nil) async throws {
        let collectionAsset = CollectionAsset(
            id: UUID().uuidString,
            collectionId: collectionId,
            assetId: assetId.rawValue,
            addedDate: Date(),
            notes: notes
        )

        modelContext.insert(collectionAsset)
        try modelContext.save()
    }

    /// Retrieves all user collections.
    public func getAllCollections() async throws -> [UserCollection] {
        try modelContext.fetch(FetchDescriptor<UserCollection>())
    }

    /// Gets assets in a specific collection.
    public func getCollectionAssets(collectionId: String) async throws -> [MediaAsset] {
        let collectionAssets = try modelContext.fetch(
            FetchDescriptor<CollectionAsset>(
                predicate: #Predicate { $0.collectionId == collectionId }
            )
        )

        // Get the actual media assets
        let assetIds = collectionAssets.map { $0.assetId }
        let assets = try modelContext.fetch(
            FetchDescriptor<PersistentMediaAsset>(
                predicate: #Predicate { assetIds.contains($0.id) }
            )
        )

        return assets.map { persistent in
            var capturedAt: PartialDate?
            if let year = persistent.capturedAtYear {
                if let month = persistent.capturedAtMonth, let day = persistent.capturedAtDay {
                    capturedAt = PartialDate.day(year: year, month: month, day: day)
                } else if let month = persistent.capturedAtMonth {
                    capturedAt = PartialDate.month(year: year, month: month)
                } else {
                    capturedAt = PartialDate.year(year)
                }
            }

            return MediaAsset(
                id: StableID(persistent.id),
                sha256: persistent.sha256,
                kind: MediaKind(rawValue: persistent.kind) ?? .image,
                originalFilename: persistent.originalFilename,
                capturedAt: capturedAt
            )
        }
    }

    // MARK: - Beauty Trends

    /// Records a beauty trend data point.
    public func recordBeautyTrend(
        userId: String,
        trendType: String,
        averageScore: Double,
        scoreChange: Double,
        dataPoints: Int,
        periodStart: Date,
        periodEnd: Date
    ) async throws {
        let trend = BeautyTrend(
            id: UUID().uuidString,
            userId: userId,
            date: Date(),
            trendType: trendType,
            averageScore: averageScore,
            scoreChange: scoreChange,
            dataPoints: dataPoints,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        modelContext.insert(trend)
        try modelContext.save()
    }

    /// Gets beauty trends for a user.
    public func getBeautyTrends(for userId: String, trendType: String? = nil) async throws -> [BeautyTrend] {
        var predicate: Predicate<BeautyTrend>
        if let trendType = trendType {
            predicate = #Predicate { $0.userId == userId && $0.trendType == trendType }
        } else {
            predicate = #Predicate { $0.userId == userId }
        }

        return try modelContext.fetch(
            FetchDescriptor<BeautyTrend>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )
    }
}
