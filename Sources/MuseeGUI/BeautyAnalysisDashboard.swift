import SwiftUI
import MuseeDomain
import MuseeVision
import MuseeCore

struct BeautyAnalysisDashboard: View {
    @ObservedObject var viewModel: MuseumViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.pink.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isProcessing {
                    processingView
                } else if let beauty = viewModel.beautyAnalysis {
                    beautyAnalysisView(beauty)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    welcomeView
                }
            }
        }
        .animation(.spring(duration: 0.5), value: viewModel.isProcessing)
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
    }

    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.processingProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.blue)
            }
            .shadow(color: .blue.opacity(0.3), radius: 10)

            VStack(spacing: 16) {
                Text("Analyzing Beauty")
                    .font(.title2.bold())

                Text("Extracting facial features and calculating beauty metrics...")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("\(Int(viewModel.processingProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
    }

    private func beautyAnalysisView(_ beauty: BeautyFeatures) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Beauty Analysis Complete")
                        .font(.title.bold())

                    HStack(spacing: 16) {
                        beautyScoreCard(
                            title: "Overall Score",
                            score: beauty.facialRatios.overallScore,
                            color: .blue,
                            icon: "star.fill"
                        )

                        beautyScoreCard(
                            title: "Golden Ratio",
                            score: beauty.facialRatios.goldenRatioScore,
                            color: .yellow,
                            icon: "circle.grid.3x3.fill"
                        )

                        beautyScoreCard(
                            title: "Symmetry",
                            score: beauty.symmetry.overallScore,
                            color: .green,
                            icon: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
                        )
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Detailed Analysis")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    facialRatiosSection(beauty.facialRatios)
                    symmetrySection(beauty.symmetry)
                    skinAnalysisSection(beauty.skinAnalysis)
                    featureAnalysisSection(beauty)
                }
            }
            .padding(.vertical)
        }
    }

    private func beautyScoreCard(title: String, score: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.1f", score * 100))
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: color.opacity(0.1), radius: 8)
        )
    }

    private func facialRatiosSection(_ ratios: FacialRatios) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Facial Proportions", icon: "face.smiling", color: .blue)

            VStack(spacing: 12) {
                ratioRow("Golden Ratio Compliance", ratios.goldenRatioScore, .yellow)
                ratioRow("Neoclassical Canons", ratios.neoclassicalScore, .purple)
                ratioRow("Facial Thirds Balance", ratios.proportionsScore, .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .blue.opacity(0.05), radius: 8)
        )
        .padding(.horizontal)
    }

    private func symmetrySection(_ symmetry: SymmetryScores) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Symmetry Analysis", icon: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill", color: .green)

            VStack(spacing: 12) {
                ratioRow("Facial Symmetry", symmetry.facialSymmetry, .green)
                ratioRow("Body Symmetry", symmetry.bodySymmetry, .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .green.opacity(0.05), radius: 8)
        )
        .padding(.horizontal)
    }

    private func skinAnalysisSection(_ skin: SkinAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Skin Analysis", icon: "hand.raised.fingers.spread.fill", color: .orange)

            VStack(spacing: 12) {
                HStack {
                    Text("Skin Quality")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", skin.overallQuality * 100))
                        .font(.headline)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("Blemishes Detected")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(skin.blemishes)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .orange.opacity(0.05), radius: 8)
        )
        .padding(.horizontal)
    }

    private func featureAnalysisSection(_ beauty: BeautyFeatures) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Feature Analysis", icon: "eye.fill", color: .purple)

            VStack(spacing: 12) {
                featureRow("Eye Appeal", beauty.eyeAnalysis.overallAppeal, .blue)
                featureRow("Nose Proportion", beauty.noseAnalysis.appeal, .green)
                featureRow("Mouth Harmony", beauty.mouthAnalysis.appeal, .pink)
                featureRow("Bone Structure", beauty.facialStructure.overallStructure, .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .purple.opacity(0.05), radius: 8)
        )
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(.headline)

            Spacer()
        }
    }

    private func ratioRow(_ label: String, _ score: Double, _ color: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * score, height: 8)
                    }
                }
                .frame(width: 80, height: 8)

                Text(String(format: "%.1f", score * 100))
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }

    private func featureRow(_ label: String, _ score: Double, _ color: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.1f", score * 100))
                .font(.headline)
                .foregroundColor(color)
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
            }

            VStack(spacing: 16) {
                Text("Analysis Failed")
                    .font(.title2.bold())
                    .foregroundColor(.red)

                Text(error)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Try Again") {
                    if let asset = viewModel.selectedAsset {
                        viewModel.selectAsset(asset)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            Spacer()
        }
        .padding()
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 16) {
                Text("Welcome to Musee")
                    .font(.title.bold())

                Text("Select an image to begin beauty analysis using advanced computer vision and golden ratio calculations.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    BeautyAnalysisDashboard(viewModel: MuseumViewModel())
}