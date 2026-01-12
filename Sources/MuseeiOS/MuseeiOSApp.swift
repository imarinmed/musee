import SwiftUI
import MuseeCore
import MuseeDomain
import MuseeMuseum
import MuseeSearch
import MuseeVision
import MuseeMetadata
import MuseeBundle

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
        assets = [] // Placeholder
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [MediaAsset] = []
}

class CameraViewModel: ObservableObject {
    // Camera logic will be implemented
}

@main
struct MuseeiOSApp: App {
    @StateObject private var museumViewModel = MuseumViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(museumViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(cameraViewModel)
                .accentColor(.blue)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MuseumView()
                .tabItem {
                    Label("Museum", systemImage: "building.2.crop.circle")
                }
                .tag(0)

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "sparkles.rectangle.stack")
                }
                .tag(1)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass.circle")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(3)
        }
        .preferredColorScheme(.dark)
    }
}



// Placeholder views with Glass interfaces
struct MuseumView: View {
    @EnvironmentObject var museumViewModel: MuseumViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Beauty Museum")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(museumViewModel.exhibits, id: \.self) { exhibit in
                            MuseumCard(exhibit: exhibit)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct MuseumCard: View {
    let exhibit: URL
    @State private var analysisCount = Int.random(in: 5...25)
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    ZStack {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.8))
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(analysisCount)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                                    .padding(8)
                                    .scaleEffect(isHovered ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                            }
                        }
                    }
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)

            Text(exhibit.lastPathComponent)
                .font(.headline)
                .foregroundStyle(.white)

            Text("Explore stunning beauty analyses")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal)
        .onTapGesture {
            // Handle tap
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation {
                        isHovered = true
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        isHovered = false
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exhibit.lastPathComponent) collection with \(analysisCount) beauty analyses")
        .accessibilityHint("Double tap to explore this beauty collection")
    }
}

struct AnalysisView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel

    var body: some View {
        ZStack {
            CameraPreview(viewModel: cameraViewModel)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Text("Live Beauty Analysis")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 20) {
                        AnalysisMetric(label: "EROSS", value: "87.3")
                        AnalysisMetric(label: "Symmetry", value: "94%")
                        AnalysisMetric(label: "Harmony", value: "89%")
                    }

                    Button(action: {
                        // Trigger camera capture and analysis
                    }) {
                        Text("Capture & Analyze")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Capsule())
                            .scaleEffect(1.0) // Ready for haptic feedback
                    }
                    .accessibilityLabel("Capture and analyze beauty")
                    .accessibilityHint("Takes a photo and analyzes beauty metrics")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                )
                .padding()
            }
        }
    }
}

struct AnalysisMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color.clear
                .background(
                    LinearGradient(
                        colors: [.indigo.opacity(0.3), .cyan.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 20) {
                TextField("Search beauty collections...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(0..<8) { _ in
                            SearchResultCard()
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SearchResultCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.6))
                )

            Text("Beauty Result")
                .font(.subheadline)
                .foregroundStyle(.white)

            Text("EROSS: 92.1")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
        )
    }
}

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.clear
                .background(
                    LinearGradient(
                        colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.8))
                        )

                    Text("Beauty Profile")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Track your beauty journey")
                        .foregroundStyle(.white.opacity(0.8))
                }

                VStack(spacing: 16) {
                    ProfileMetric(title: "Total Analyses", value: "47")
                    ProfileMetric(title: "Average EROSS", value: "85.2")
                    ProfileMetric(title: "Collections", value: "12")
                }
                .padding(.horizontal)
            }
            .padding(.top, 60)
        }
    }
}

struct ProfileMetric: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

// Placeholder Camera Preview
struct CameraPreview: View {
    let viewModel: CameraViewModel

    var body: some View {
        Color.black
            .overlay(
                Text("Camera Preview")
                    .foregroundStyle(.white)
            )
    }
}

