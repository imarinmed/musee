import Foundation
import MuseeCore
import MuseeDomain
import MuseeSearch

/// Service for handling search operations and result management.
public class SearchService {
    private let searchEngine: SearchEngine

    public init(searchEngine: SearchEngine) {
        self.searchEngine = searchEngine
    }

    /// Performs a faceted search with the given query.
    /// - Parameter query: Search parameters and filters
    /// - Returns: Result containing array of matching media assets or error
    public func performSearch(query: FacetedSearchQuery) async -> Result<[MediaAsset], MuseeError> {
        do {
            let results = try await searchEngine.search(query: query)
            return .success(results)
        } catch let error as MuseeError {
            return .failure(error)
        } catch {
            return .failure(.searchFailed("Unexpected search error: \(error.localizedDescription)"))
        }
    }

    /// Finds assets similar to the given asset.
    /// - Parameters:
    ///   - assetId: ID of the reference asset
    ///   - limit: Maximum number of similar assets to return
    /// - Returns: Result containing array of similar media assets or error
    public func findSimilar(to assetId: StableID, limit: Int = 10) async -> Result<[MediaAsset], MuseeError> {
        do {
            let results = try await searchEngine.findSimilar(to: assetId, limit: limit)
            return .success(results)
        } catch let error as MuseeError {
            return .failure(error)
        } catch {
            return .failure(.searchFailed("Failed to find similar assets: \(error.localizedDescription)"))
        }
    }

    /// Indexes an asset for search.
    /// - Parameters:
    ///   - asset: Asset to index
    ///   - tags: Associated tags for the asset
    /// - Returns: Result indicating success or error
    public func indexAsset(_ asset: MediaAsset, tags: [Tag]) async -> Result<Void, MuseeError> {
        do {
            try await searchEngine.index(asset: asset, tags: tags)
            return .success(())
        } catch let error as MuseeError {
            return .failure(error)
        } catch {
            return .failure(.searchFailed("Failed to index asset: \(error.localizedDescription)"))
        }
    }

    /// Sorts assets according to specified options.
    /// - Parameters:
    ///   - assets: Assets to sort
    ///   - options: Sorting configuration
    /// - Returns: Result containing sorted array of assets or error
    public func sortAssets(_ assets: [MediaAsset], options: SortOptions) async -> Result<[MediaAsset], MuseeError> {
        do {
            let results = try await searchEngine.sort(assets: assets, options: options)
            return .success(results)
        } catch let error as MuseeError {
            return .failure(error)
        } catch {
            return .failure(.searchFailed("Failed to sort assets: \(error.localizedDescription)"))
        }
    }


}