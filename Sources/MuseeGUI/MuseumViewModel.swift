import Foundation
import SwiftUI
import MuseeCore
import MuseeDomain
import MuseeMuseum
import MuseeSearch
import MuseeVision
import MuseeMetadata

/// View model for managing museum browsing and analysis operations.
/// Coordinates between UI, data services, and analysis engines.
@MainActor
class MuseumViewModel: ObservableObject {
    // MARK: - Published State
    @Published var museum: MuseumLibrary?
    @Published var wings: [MuseumIndex.Wing] = []
    @Published var selectedWing: MuseumIndex.Wing?
    @Published var exhibits: [URL] = []
    @Published var selectedExhibit: URL?
    @Published var assets: [MediaAsset] = []
    @Published var selectedAsset: MediaAsset?
    @Published var beautyAnalysis: BeautyFeatures?
    @Published var searchResults: [MediaAsset] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var errorMessage: String?

    // MARK: - Services
    private let beautyAnalysisService: BeautyAnalysisService
    private let searchService: SearchService
    private let dataLoadingService: DataLoadingService

    init(
        beautyAnalysisService: BeautyAnalysisService = BeautyAnalysisService(),
        searchService: SearchService? = nil,
        dataLoadingService: DataLoadingService = DataLoadingService()
    ) {
        self.beautyAnalysisService = beautyAnalysisService
        self.searchService = searchService ?? SearchService(searchEngine: Self.createDefaultSearchEngine())
        self.dataLoadingService = dataLoadingService

        // Initialize with demo data
        loadDemoMuseum()
    }

    private static func createDefaultSearchEngine() -> SearchEngine {
        // For now, create a simple wrapper that provides basic search functionality
        // In production, this would be properly configured with dependency injection
        class BasicSearchEngine: SearchEngine {
            func search(query: FacetedSearchQuery) async throws -> [MediaAsset] { [] }
            func findSimilar(to assetId: StableID, limit: Int) async throws -> [MediaAsset] { [] }
            func index(asset: MediaAsset, tags: [Tag]) async throws {}
            func sort(assets: [MediaAsset], options: SortOptions) async throws -> [MediaAsset] { assets }
            func curate(assets: [MediaAsset], rules: [CurationRule]) async throws -> [MediaAsset] { assets }
            func createSmartCollection(_ collection: MuseeSearch.SmartCollection) async throws {}
            func getSmartCollectionAssets(_ collectionId: StableID) async throws -> [MediaAsset] { [] }
        }
        return BasicSearchEngine()
    }

    private func loadDemoMuseum() {
        wings = dataLoadingService.loadDemoWings()
        assets = dataLoadingService.loadDemoAssets()
    }

    func selectWing(_ wing: MuseumIndex.Wing) {
        selectedWing = wing
        // TODO: Load wing exhibits
    }

    func selectExhibit(_ exhibit: URL) {
        selectedExhibit = exhibit
        // TODO: Load exhibit assets
    }

    func selectAsset(_ asset: MediaAsset) {
        selectedAsset = asset
        analyzeBeauty(for: asset)
    }

    private func analyzeBeauty(for asset: MediaAsset) {
        Task { [weak self] in
            await MainActor.run {
                self?.isProcessing = true
                self?.processingProgress = 0.0
            }

            // Simulate processing progress
            for progress in stride(from: 0.0, to: 1.0, by: 0.1) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    self?.processingProgress = progress
                }
            }

            // Use demo data for now - TODO: Load actual image data
            let demoData = Data() // Empty data for demo
            let result = await self?.beautyAnalysisService.analyzeBeauty(from: demoData)

            await MainActor.run {
                if let result = result {
                    switch result {
                    case .success(let beautyFeatures):
                        self?.beautyAnalysis = beautyFeatures
                    case .failure(let error):
                        self?.errorMessage = "Beauty analysis failed: \(error.localizedDescription)"
                        self?.simulateBeautyAnalysis()
                    }
                }
                self?.isProcessing = false
            }
        }
    }

    private func simulateBeautyAnalysis() {
        beautyAnalysis = createDemoBeautyFeatures()
    }

    private func createDemoBeautyFeatures() -> BeautyFeatures {
        BeautyFeatures(
            facialRatios: FacialRatios(
                eyeToNoseRatio: 1.618, noseToMouthRatio: 1.618, faceWidthRatio: 1.618,
                eyeToEyeRatio: 0.46, faceLengthToWidth: 1.5, foreheadToFace: 0.33,
                upperThird: 0.33, middleThird: 0.33, lowerThird: 0.34,
                eyeWidthRatio: 0.3, eyeHeightRatio: 0.25,
                noseWidthRatio: 0.25, noseLengthRatio: 0.3,
                mouthWidthRatio: 0.4, lipFullnessRatio: 1.0,
                goldenRatioScore: 0.85, neoclassicalScore: 0.75, proportionsScore: 0.9, overallScore: 0.8
            ),
            bodyRatios: BodyRatios(waistToHipRatio: 0.7, shoulderToWaistRatio: 1.618, overallScore: 0.8),
            symmetry: SymmetryScores(facialSymmetry: 0.9, bodySymmetry: 0.8, overallScore: 0.85),
            skinAnalysis: SkinAnalysis(
                texture: 0.9, tone: 0.85, radiance: 0.8,
                color: SkinColor(undertone: .neutral, brightness: 0.7, saturation: 0.3),
                blemishes: 2, overallQuality: 0.82
            ),
            eyeAnalysis: EyeAnalysis(
                shape: .almond, symmetry: 0.9, irisVisibility: 0.8,
                eyelidPosition: 0.7, eyebrowArch: 0.85, overallAppeal: 0.82
            ),
            noseAnalysis: NoseAnalysis(
                bridgeWidth: 0.6, nostrilSymmetry: 0.9, tipDefinition: 0.8,
                overallProportion: 0.85, appeal: 0.82
            ),
            mouthAnalysis: MouthAnalysis(
                lipFullness: 0.9, smileArc: 0.8, teethAlignment: 0.95,
                cupidsBow: 0.7, symmetry: 0.88, appeal: 0.85
            ),
            facialStructure: FacialStructure(
                cheekboneProminence: 0.75, jawlineDefinition: 0.8,
                chinShape: .pointed, foreheadProportion: 0.65, overallStructure: 0.78
            ),
            features: FeatureScores(
                skinQuality: 0.82, blemishCount: 2, muscleDefinition: 0.7,
                breastSymmetry: nil, overallScore: 0.76
            )
        )
    }

    func performSearch(query: String, filters: [String: Any] = [:]) {
        let searchService = self.searchService
        Task { [weak self] in
            let searchQuery = FacetedSearchQuery(text: query.isEmpty ? nil : query)
            let result = await searchService.performSearch(query: searchQuery)

            await MainActor.run {
                switch result {
                case .success(let results):
                    self?.searchResults = results
                case .failure(let error):
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    self?.searchResults = []
                }
            }
        }
    }

    func performSorting(by sortBy: SortOptions.SortBy, order: SortOptions.SortOrder) {
        let searchService = self.searchService
        let currentAssets = self.assets
        Task { [weak self] in
            let sortOptions = SortOptions(
                primarySort: sortBy,
                primaryOrder: order
            )
            let result = await searchService.sortAssets(currentAssets, options: sortOptions)

            await MainActor.run {
                switch result {
                case .success(let sorted):
                    self?.assets = sorted
                case .failure(let error):
                    self?.errorMessage = "Sorting failed: \(error.localizedDescription)"
                }
            }
        }
    }
}