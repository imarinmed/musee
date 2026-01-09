import SwiftUI
import MuseeCore
import MuseeDomain
import MuseeSearch

struct SearchView: View {
    @ObservedObject var viewModel: MuseumViewModel

    @State private var searchQuery = ""
    @State private var selectedSortBy: SortOptions.SortBy = .capturedAt
    @State private var selectedSortOrder: SortOptions.SortOrder = .descending
    @State private var selectedMediaType: MediaKind? = nil
    @State private var beautyScoreRange: ClosedRange<Double> = 0...100
    @State private var symmetryScoreRange: ClosedRange<Double> = 0...100

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search beauty, tags, filenames...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Search", action: performSearch)
                        .buttonStyle(.borderedProminent)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 4)
                )
                .padding(.horizontal)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        sortPicker
                        mediaTypePicker
                        beautyScoreFilter
                        symmetryFilter
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)

            Divider()

            // Results
            if viewModel.searchResults.isEmpty && (viewModel.errorMessage != nil) {
                errorView
            } else if viewModel.searchResults.isEmpty {
                emptyStateView
            } else {
                searchResultsView
            }
        }
        .navigationTitle("Advanced Search")
    }

    private var sortPicker: some View {
        Menu {
            Picker("Sort By", selection: $selectedSortBy) {
                Text("Date Captured").tag(SortOptions.SortBy.capturedAt)
                Text("Alphabetical").tag(SortOptions.SortBy.alphabetical)
            }

            Divider()

            Picker("Order", selection: $selectedSortOrder) {
                Text("Ascending").tag(SortOptions.SortOrder.ascending)
                Text("Descending").tag(SortOptions.SortOrder.descending)
            }
        } label: {
            filterButton(
                title: sortTitle,
                icon: "arrow.up.arrow.down",
                color: .blue
            )
        }
    }

    private var sortTitle: String {
        let order = selectedSortOrder == .ascending ? "↑" : "↓"
        switch selectedSortBy {
        case .capturedAt: return "Date \(order)"
        case .alphabetical: return "Name \(order)"
        default: return "Sort \(order)"
        }
    }

    private var mediaTypePicker: some View {
        Menu {
            Button(action: { selectedMediaType = nil }) {
                Label("All Types", systemImage: selectedMediaType == nil ? "checkmark" : "")
            }

            Button(action: { selectedMediaType = .image }) {
                Label("Images", systemImage: selectedMediaType == .image ? "checkmark" : "")
            }

            Button(action: { selectedMediaType = .video }) {
                Label("Videos", systemImage: selectedMediaType == .video ? "checkmark" : "")
            }
        } label: {
            let title = selectedMediaType?.rawValue.capitalized ?? "All Types"
            return filterButton(
                title: title,
                icon: "photo",
                color: .green
            )
        }
    }

    private var beautyScoreFilter: some View {
        Menu {
            VStack(spacing: 16) {
                Text("Beauty Score Range")
                    .font(.headline)

                RangeSlider(range: $beautyScoreRange, bounds: 0...100)
                    .frame(height: 40)

                Text(String(format: "%.0f - %.0f", beautyScoreRange.lowerBound, beautyScoreRange.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 250)
            .padding()
        } label: {
            filterButton(
                title: String(format: "Beauty: %.0f-%.0f", beautyScoreRange.lowerBound, beautyScoreRange.upperBound),
                icon: "star",
                color: .yellow
            )
        }
    }

    private var symmetryFilter: some View {
        Menu {
            VStack(spacing: 16) {
                Text("Symmetry Score Range")
                    .font(.headline)

                RangeSlider(range: $symmetryScoreRange, bounds: 0...100)
                    .frame(height: 40)

                Text(String(format: "%.0f - %.0f", symmetryScoreRange.lowerBound, symmetryScoreRange.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 250)
            .padding()
        } label: {
            filterButton(
                title: String(format: "Symmetry: %.0f-%.0f", symmetryScoreRange.lowerBound, symmetryScoreRange.upperBound),
                icon: "arrow.left.and.right",
                color: .purple
            )
        }
    }

    private func filterButton(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))

            Text(title)
                .font(.system(size: 14, weight: .medium))

            Image(systemName: "chevron.down")
                .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red.opacity(0.8))

            VStack(spacing: 12) {
                Text("Search Error")
                    .font(.title2.bold())

                Text(viewModel.errorMessage ?? "An unexpected error occurred")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Try Again") {
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            Spacer()
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.6))

            VStack(spacing: 12) {
                Text("No Results Found")
                    .font(.title2.bold())

                Text(searchQuery.isEmpty ?
                    "Enter a search query to find beautiful assets" :
                    "Try adjusting your filters or search terms")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if !searchQuery.isEmpty {
                Button("Clear Search") {
                    searchQuery = ""
                    viewModel.searchResults = []
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.searchResults, id: \.id) { asset in
                    AssetCard(asset: asset, viewModel: viewModel)
                }
            }
            .padding()
        }
    }

    private func performSearch() {
        // For now, filter locally since we don't have real search engine
        var filteredAssets = viewModel.assets

        // Apply text search
        if !searchQuery.isEmpty {
            filteredAssets = filteredAssets.filter { asset in
                asset.originalFilename?.localizedCaseInsensitiveContains(searchQuery) ?? false
            }
        }

        // Apply media type filter
        if let mediaType = selectedMediaType {
            filteredAssets = filteredAssets.filter { $0.kind == mediaType }
        }

        // Apply beauty score filter (placeholder - would use real beauty scores)
        if beautyScoreRange != 0...100 {
            // Placeholder: filter would use actual beauty analysis scores
            filteredAssets = filteredAssets.filter { _ in
                Double.random(in: 0...100) >= beautyScoreRange.lowerBound &&
                Double.random(in: 0...100) <= beautyScoreRange.upperBound
            }
        }

        // Apply sorting
        filteredAssets.sort { lhs, rhs in
            switch selectedSortBy {
            case .capturedAt:
                        let lhsDate = lhs.capturedAt ?? PartialDate.year(1900)
                        let rhsDate = rhs.capturedAt ?? PartialDate.year(1900)
                return selectedSortOrder == .ascending ? lhsDate < rhsDate : lhsDate > rhsDate
            case .alphabetical:
                let lhsName = lhs.originalFilename ?? ""
                let rhsName = rhs.originalFilename ?? ""
                return selectedSortOrder == .ascending ? lhsName < rhsName : lhsName > rhsName
            default:
                return selectedSortOrder == .ascending ?
                    lhs.id.rawValue < rhs.id.rawValue :
                    lhs.id.rawValue > rhs.id.rawValue
            }
        }

        viewModel.searchResults = filteredAssets
    }
}

struct AssetCard: View {
    let asset: MediaAsset
    @ObservedObject var viewModel: MuseumViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Asset preview placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(4/3, contentMode: .fit)

                Image(systemName: asset.kind == .image ? "photo" : "video")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.originalFilename ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(asset.kind.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())

                    Spacer()

                    if let year = asset.capturedAt?.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
        .onTapGesture {
            viewModel.selectAsset(asset)
        }
    }
}

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                // Selected range
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(
                        width: width(for: range, in: geometry.size.width),
                        height: 4
                    )
                    .offset(x: offset(for: range.lowerBound, in: geometry.size.width))

                // Lower bound handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: offset(for: range.lowerBound, in: geometry.size.width))

                // Upper bound handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: offset(for: range.upperBound, in: geometry.size.width))
            }
        }
    }

    private func offset(for value: Double, in totalWidth: CGFloat) -> CGFloat {
        let ratio = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return ratio * totalWidth - totalWidth / 2
    }

    private func width(for range: ClosedRange<Double>, in totalWidth: CGFloat) -> CGFloat {
        let ratio = (range.upperBound - range.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return ratio * totalWidth
    }
}

#Preview {
    SearchView(viewModel: MuseumViewModel())
}