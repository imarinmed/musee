import SwiftUI
import MuseeCore
import MuseeDomain
import MuseeMuseum
import MuseeSearch
import MuseeVision

@main
struct MuseeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}

struct ContentView: View {
    @StateObject private var museumViewModel: MuseumViewModel = {
        let searchService = SearchService(searchEngine: createDefaultSearchEngine())
        return MuseumViewModel(searchService: searchService)
    }()
    @State private var selectedView: NavigationItem = .museum

    private static func createDefaultSearchEngine() -> SearchEngine {
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

    enum NavigationItem: String, CaseIterable, Identifiable {
        case museum = "Museum"
        case beauty = "Beauty Analysis"
        case search = "Search"
        case timeline = "Timeline"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .museum: return "building.2"
            case .beauty: return "sparkles"
            case .search: return "magnifyingglass"
            case .timeline: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(NavigationItem.allCases, selection: $selectedView) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Musee")
            .listStyle(.sidebar)

        } detail: {
            // Main content
            switch selectedView {
            case .museum:
                MuseumBrowserView(viewModel: museumViewModel)
            case .beauty:
                BeautyAnalysisDashboard(viewModel: museumViewModel)
            case .search:
                SearchView(viewModel: museumViewModel)
            case .timeline:
                Text("Timeline View - Coming Soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: importAssets) {
                    Label("Import", systemImage: "plus")
                }

                Button(action: exportMuseum) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(action: backupMuseum) {
                    Label("Backup", systemImage: "externaldrive")
                }
            }
        }
    }

    private func importAssets() {
        // Basic implementation - open file picker
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [.image, .video]

        if openPanel.runModal() == .OK {
            // TODO: Process selected files and add to museum
            print("Selected \(openPanel.urls.count) files for import")
        }
    }

    private func exportMuseum() {
        // Basic implementation - save panel for export
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.zip]
        savePanel.nameFieldStringValue = "museum_export.zip"

        if savePanel.runModal() == .OK {
            if let exportURL = savePanel.url {
                // TODO: Export museum data to the selected location
                print("Exporting museum to: \(exportURL.path)")
            }
        }
    }

    private func backupMuseum() {
        // Basic implementation - backup to default location
        let backupURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Musee")
            .appendingPathComponent("backups")
            .appendingPathComponent("museum_backup_\(Date().ISO8601Format()).zip")

        if let backupURL = backupURL {
            do {
                try FileManager.default.createDirectory(at: backupURL.deletingLastPathComponent(),
                                                      withIntermediateDirectories: true)
                // TODO: Create actual backup
                print("Creating backup at: \(backupURL.path)")
            } catch {
                print("Failed to create backup directory: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}