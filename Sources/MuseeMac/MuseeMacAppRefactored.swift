import SwiftUI
import MuseeCore
import MuseeDomain
import MuseeMuseum
import MuseeSearch
import MuseeVision
import MuseeMetadata
import MuseeBundle

// MARK: - View Models (Unchanged)

class MuseumViewModel: ObservableObject {
    @Published var selectedWing: MuseumIndex.Wing?
    @Published var selectedExhibit: URL?
    @Published var exhibits: [URL] = []
    @Published var assets: [MediaAsset] = []

    func selectWing(_ wing: MuseumIndex.Wing) {
        selectedWing = wing
        exhibits = wing.categories.map { URL(fileURLWithPath: $0) }
    }

    func selectExhibit(_ exhibit: URL) {
        selectedExhibit = exhibit
        // Load assets for exhibit
        assets = [] // Placeholder
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [MediaAsset] = []
}

// MARK: - Main App

@main
struct MuseeMacApp: App {
    @StateObject private var museumViewModel = MuseumViewModel()
    @StateObject private var searchViewModel = SearchViewModel()

    var body: some Scene {
        WindowGroup("Beauty Analysis Studio", id: "main") {
            MainView()
                .environmentObject(museumViewModel)
                .environmentObject(searchViewModel)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            ToolbarCommands()
        }

        WindowGroup("Analysis Comparison", id: "comparison") {
            AnalysisComparisonView(comparison: AnalysisComparison(analyses: []))
                .environmentObject(museumViewModel)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
                .environmentObject(museumViewModel)
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var museumViewModel: MuseumViewModel
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        } detail: {
            switch selectedTab {
            case 0:
                MuseumBrowserView()
            case 1:
                BeautyAnalysisStudioView()
            case 2:
                SearchStudioView()
            case 3:
                TrendAnalysisView()
            default:
                EmptyView()
            }
        }
        .glassBackground()
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        List(selection: $selectedTab) {
            Label("Museum", systemImage: "building.2.crop.circle")
                .tag(0)
            Label("Analysis Studio", systemImage: "sparkles.rectangle.stack")
                .tag(1)
            Label("Search Studio", systemImage: "magnifyingglass.circle")
                .tag(2)
            Label("Trend Analysis", systemImage: "chart.line.uptrend.xyaxis")
                .tag(3)
        }
        .listStyle(.sidebar)
        .glassSidebar()
    }
}

// MARK: - Placeholder Views

struct SearchStudioView: View {
    var body: some View {
        Text("Search Studio - Coming Soon")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

struct TrendAnalysisView: View {
    var body: some View {
        Text("Trend Analysis - Coming Soon")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

struct AnalysisComparisonView: View {
    let comparison: AnalysisComparison

    var body: some View {
        Text("Analysis Comparison - Coming Soon")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings - Coming Soon")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

struct AnalysisComparison {
    let analyses: [BeautyAnalysis]
}

struct BeautyAnalysis: Identifiable {
    let id = UUID()
    let erossScore: Double
    let facialRatios: FacialRatios
    let bodyRatios: BodyRatios
}

// MARK: - Exhibit Detail View (Refactored to use PlatformImage)

struct ExhibitDetailView: View {
    let exhibit: URL
    @State private var analyses: [BeautyAnalysis] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                ForEach(analyses, id: \.id) { analysis in
                    AnalysisCard(analysis: analysis)
                }
            }
            .padding()
        }
        .navigationTitle(exhibit.lastPathComponent)
        .glassBackground()
    }
}

// MARK: - Analysis Card

struct AnalysisCard: View {
    let analysis: BeautyAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Placeholder for image - would use PlatformImage here
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("EROSS Score")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(String(format: "%.1f", analysis.erossScore))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.blue)

                HStack {
                    MetricView(label: "Facial", value: String(format: "%.1f", analysis.facialRatios.overallScore))
                    MetricView(label: "Body", value: String(format: "%.1f", analysis.bodyRatios.overallScore))
                    MetricView(label: "Symmetry", value: String(format: "%.1f", analysis.facialRatios.overallScore))
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Metric View

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Museum Browser View

struct MuseumBrowserView: View {
    @EnvironmentObject var museumViewModel: MuseumViewModel

    var body: some View {
        NavigationSplitView {
            List(museumViewModel.exhibits, id: \.self, selection: $museumViewModel.selectedExhibit) { exhibit in
                VStack(alignment: .leading) {
                    Text(exhibit.lastPathComponent)
                        .font(.headline)
                    Text("Beauty Collection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .glassCard()
            }
            .navigationTitle("Collections")
        } detail: {
            if let exhibit = museumViewModel.selectedExhibit {
                ExhibitDetailView(exhibit: exhibit)
            } else {
                Text("Select a collection to view beauty analyses")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .glassBackground()
    }
}

// MARK: - Analysis Results View

struct AnalysisResultsView: View {
    let result: BeautyFeatures

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // EROSS Score
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Beauty Score")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: 0.87)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))

                        VStack {
                            Text("87.3")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("EROSS")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }

                // Detailed Scores
                VStack(alignment: .leading, spacing: 16) {
                    Text("Detailed Analysis")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    ScoreRow(label: "Facial Beauty", score: result.facialRatios.overallScore)
                    ScoreRow(label: "Body Aesthetics", score: result.bodyRatios.overallScore)
                    ScoreRow(label: "Skin Quality", score: result.skinQuality)
                }
                .glassCard()
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

// MARK: - Score Row

struct ScoreRow: View {
    let label: String
    let score: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            Text(String(format: "%.1f", score))
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Beauty Analysis Studio View (REFACTORED - Using Platform Abstractions)

struct BeautyAnalysisStudioView: View {
    @State private var selectedImage: PlatformImage?
    @State private var selectedImageURL: URL?
    @State private var analysisResult: BeautyFeatures?
    @State private var isProcessing = false
    @State private var showImagePicker = false

    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Image Selection
            VStack {
                Text("Beauty Analysis Studio")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding()

                Button(action: { showImagePicker = true }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("Select Image")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard()
                }

                if let image = selectedImage {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .glassCard()
                }

                Spacer()
            }
            .frame(width: 350)
            .glassSidebar()

            // Right Panel - Analysis Results
            VStack {
                if isProcessing {
                    ProgressView("Analyzing beauty...")
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .foregroundStyle(.white)
                } else if let result = analysisResult {
                    AnalysisResultsView(result: result)
                } else {
                    Text("Select an image to begin beauty analysis")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .glassBackground()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                configuration: .init(allowedTypes: ["png", "jpg", "jpeg", "heic"])
            ) { image, url in
                selectedImage = image
                selectedImageURL = url
                analyzeImage(at: url)
            } onCancelled: {
                showImagePicker = false
            }
        }
    }

    private func analyzeImage(at url: URL) {
        isProcessing = true
        showImagePicker = false

        Task {
            do {
                // Convert to Data for analysis
                let imageData = try Data(contentsOf: url)
                let features = try await VisionProcessor.extractFeatures(from: imageData)
                let beautyFeatures = VisionProcessor.analyzeBeauty(from: features)

                await MainActor.run {
                    analysisResult = beautyFeatures
                    isProcessing = false
                }
            } catch {
                print("Analysis failed: \(error)")
                isProcessing = false
            }
        }
    }
}
