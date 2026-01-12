import SwiftUI
import MuseeDomain
import MuseeVision
import MuseeCore

struct AssetViewer: View {
    @ObservedObject var viewModel: MuseumViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let asset = viewModel.selectedAsset {
                // Asset header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(asset.originalFilename ?? "Untitled")
                            .font(.title)
                        Spacer()
                        Text(asset.kind.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let capturedAt = asset.capturedAt {
                        Text("Captured: \(capturedAt.year ?? 0)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("ID: \(asset.id.rawValue.prefix(8))...", systemImage: "tag")
                        Spacer()
                        Label("SHA256: \(asset.sha256.prefix(8))...", systemImage: "lock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.windowBackgroundColor))

                Divider()

                HStack(spacing: 0) {
                    // Asset preview
                    VStack {
                        // Placeholder for actual asset display
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                VStack {
                                    Image(systemName: asset.kind == .image ? "photo.fill" : "video.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    Text("Asset Preview")
                                        .foregroundColor(.secondary)
                                }
                            )
                            .aspectRatio(4/3, contentMode: .fit)
                            .padding()

                        Spacer()
                    }
                    .frame(width: 400)
                    .background(Color(.controlBackgroundColor))

                    Divider()

                    // Beauty analysis panel
                    VStack(alignment: .leading) {
                        Text("Beauty Analysis")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.isProcessing {
                            VStack(spacing: 16) {
                                ProgressView("Analyzing beauty...", value: viewModel.processingProgress)
                                    .progressViewStyle(.linear)
                                    .padding(.horizontal)

                                Text("Processing with AI Vision...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else if let beauty = viewModel.beautyAnalysis {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    EROSSScoreView(beauty: beauty)
                                    FacialAnalysisView(beauty: beauty)
                                    SkinAnalysisView(beauty: beauty)
                                    BodyAnalysisView(beauty: beauty)
                                }
                                .padding()
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)

                                Text("No beauty analysis available")
                                    .foregroundColor(.secondary)

                                Button("Analyze Beauty") {
                                    if let asset = viewModel.selectedAsset {
                                        viewModel.selectAsset(asset) // Trigger analysis
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Select an asset to view beauty analysis")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct EROSSScoreView: View {
    let beauty: BeautyFeatures

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EROSS Score")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(85.0 / 100))
                        .stroke(Color.blue, lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text(String(format: "%.0f", 85.0))
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ScoreBreakdownRow(label: "Facial Harmony", score: beauty.facialRatios.overallScore)
                ScoreBreakdownRow(label: "Skin Quality", score: beauty.skinAnalysis.overallQuality)
                ScoreBreakdownRow(label: "Eye Appeal", score: beauty.eyeAnalysis.overallAppeal)
                ScoreBreakdownRow(label: "Symmetry", score: beauty.symmetry.overallScore)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScoreBreakdownRow: View {
    let label: String
    let score: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.1f", score * 100))
                .fontWeight(.medium)
            ProgressView(value: score)
                .progressViewStyle(.linear)
                .frame(width: 60)
        }
    }
}

struct FacialAnalysisView: View {
    let beauty: BeautyFeatures

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Facial Analysis")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                MetricRow(label: "Golden Ratio Score", value: beauty.facialRatios.goldenRatioScore * 100)
                MetricRow(label: "Neoclassical Score", value: beauty.facialRatios.neoclassicalScore * 100)
                MetricRow(label: "Facial Proportions", value: beauty.facialRatios.proportionsScore * 100)
                MetricRow(label: "Eye Symmetry", value: beauty.eyeAnalysis.symmetry * 100)
                MetricRow(label: "Nose Appeal", value: beauty.noseAnalysis.appeal * 100)
                MetricRow(label: "Mouth Appeal", value: beauty.mouthAnalysis.appeal * 100)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SkinAnalysisView: View {
    let beauty: BeautyFeatures

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skin Analysis")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                MetricRow(label: "Texture Quality", value: beauty.skinAnalysis.texture * 100)
                MetricRow(label: "Tone Evenness", value: beauty.skinAnalysis.tone * 100)
                MetricRow(label: "Radiance", value: beauty.skinAnalysis.radiance * 100)
                HStack {
                    Text("Undertone")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(beauty.skinAnalysis.color.undertone.rawValue.capitalized)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Blemishes")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(beauty.skinAnalysis.blemishes)")
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BodyAnalysisView: View {
    let beauty: BeautyFeatures

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Analysis")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                if let whr = beauty.bodyRatios.waistToHipRatio {
                    MetricRow(label: "Waist-to-Hip Ratio", value: whr * 100)
                }
                MetricRow(label: "Body Symmetry", value: beauty.symmetry.bodySymmetry * 100)
                MetricRow(label: "Muscle Definition", value: beauty.features.muscleDefinition * 100)
                MetricRow(label: "Facial Structure", value: beauty.facialStructure.overallStructure * 100)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricRow: View {
    let label: String
    let value: Double

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.1f", value))
                .fontWeight(.medium)
        }
    }
}
