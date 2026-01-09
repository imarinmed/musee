import SwiftUI
import MuseeMuseum
import MuseeDomain

struct MuseumBrowserView: View {
    @ObservedObject var viewModel: MuseumViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Museum Browser")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Explore your curated collections")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.windowBackgroundColor))

            Divider()

            HStack(spacing: 0) {
                // Wings sidebar
                VStack(alignment: .leading) {
                    Text("Wings")
                        .font(.headline)
                        .padding(.horizontal)

                    List(viewModel.wings, selection: $viewModel.selectedWing) { wing in
                        WingRow(wing: wing)
                            .tag(wing)
                    }
                    .listStyle(.plain)
                }
                .frame(width: 250)
                .background(Color(.controlBackgroundColor))

                Divider()

                // Exhibits and assets
                VStack {
                    if let selectedWing = viewModel.selectedWing {
                        WingDetailView(wing: selectedWing, viewModel: viewModel)
                    } else {
                        Text("Select a wing to browse")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Museum")
    }
}

struct WingRow: View {
    let wing: MuseumIndex.Wing

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(wing.name)
                    .font(.system(size: 14, weight: .medium))
                if let description = wing.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct WingDetailView: View {
    let wing: MuseumIndex.Wing
    @ObservedObject var viewModel: MuseumViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Wing header
            VStack(alignment: .leading, spacing: 8) {
                Text(wing.name)
                    .font(.title2)
                    .fontWeight(.bold)
                if let description = wing.description {
                    Text(description)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Assets grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.assets, id: \.id) { asset in
                        VStack(alignment: .leading, spacing: 8) {
                            // Asset preview placeholder
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: asset.kind == .image ? "photo" : "video")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text(asset.originalFilename ?? "Untitled")
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(.secondary)
                                    }
                                )
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.originalFilename ?? "Untitled")
                                    .font(.caption)
                                    .lineLimit(1)

                                if let capturedAt = asset.capturedAt {
                                    Text(capturedAt.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                // Beauty score indicator
                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("Analyzed")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)
                        .onTapGesture {
                            viewModel.selectAsset(asset)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    MuseumBrowserView(viewModel: MuseumViewModel())
}