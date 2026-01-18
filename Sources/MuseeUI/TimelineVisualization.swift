import SwiftUI
import MuseeBundle

/// Timeline visualization components for muse evolution tracking
public extension MuseeUI {
    
    /// A comprehensive timeline view showing muse evolution over time
    struct MuseEvolutionTimeline: View {
        let timeline: MuseeTemporal.EvolutionTimeline
        let evolutionReport: EvolutionReport?
        @State private var selectedSnapshot: MuseeTemporal.MuseSnapshot?
        @State private var showingComparison = false
        
        public init(timeline: MuseeTemporal.EvolutionTimeline, evolutionReport: EvolutionReport? = nil) {
            self.timeline = timeline
            self.evolutionReport = evolutionReport
        }
        
        public var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeline header
                    timelineHeader
                    
                    // Evolution summary (if available)
                    if let report = evolutionReport {
                        evolutionSummaryView(report: report)
                    }
                    
                    // Timeline visualization
                    timelineVisualization
                    
                    // Snapshot details
                    if let snapshot = selectedSnapshot {
                        snapshotDetailView(snapshot: snapshot)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showingComparison) {
                if let before = selectedSnapshot,
                   let afterIndex = timeline.snapshots.firstIndex(where: { $0.timestamp > before.timestamp }),
                   afterIndex < timeline.snapshots.count {
                    snapshotComparisonView(before: before, after: timeline.snapshots[afterIndex])
                }
            }
        }
        
        private var timelineHeader: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Muse Evolution Timeline")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(timeline.snapshots.count) snapshots • \(timeline.changeEvents.count) change events")
                    .foregroundColor(.secondary)
                
                if let first = timeline.snapshots.first, let last = timeline.snapshots.last {
                    Text("From \(formatDate(first.timestamp)) to \(formatDate(last.timestamp))")
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private func evolutionSummaryView(report: EvolutionReport) -> some View {
            MuseumCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Evolution Summary")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Changes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(report.totalChanges)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Change Rate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f/day", report.averageChangeVelocity))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Transformation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(report.transformationIntensity)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(report.overallMagnitude > 0.7 ? .orange : .green)
                        }
                    }
                    
                    if !report.keyTransformations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Transformations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(report.keyTransformations, id: \.self) { transformation in
                                Text("• \(transformation)")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        
        private var timelineVisualization: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Evolution Timeline")
                    .font(.headline)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Timeline axis
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 2)
                        
                        // Snapshots
                        ForEach(timeline.snapshots.indices, id: \.self) { index in
                            let snapshot = timeline.snapshots[index]
                            let position = calculatePosition(for: snapshot.timestamp, in: geometry.size.width)
                            
                            VStack(spacing: 4) {
                                // Snapshot marker
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedSnapshot = snapshot
                                    }
                                
                                // Date label
                                Text(formatDate(snapshot.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                                    .offset(y: 10)
                            }
                            .position(x: position, y: 6)
                        }
                        
                        // Change events
                        ForEach(timeline.changeEvents, id: \.id) { event in
                            let position = calculatePosition(for: event.timestamp, in: geometry.size.width)
                            
                            VStack(spacing: 4) {
                                // Event marker
                                Image(systemName: eventIcon(for: event.type))
                                    .foregroundColor(eventColor(for: event.type))
                                    .font(.system(size: 10))
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 16, height: 16)
                                    )
                                
                                // Event type label
                                Text(eventTypeLabel(for: event.type))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                                    .offset(y: 10)
                            }
                            .position(x: position, y: -10)
                        }
                    }
                    .frame(height: 60)
                }
                .frame(height: 80)
                
                // Legend
                HStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text("Snapshots")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 8))
                        Text("Change Events")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        
        private func snapshotDetailView(snapshot: MuseeTemporal.MuseSnapshot) -> some View {
            MuseumCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Snapshot Details")
                        .font(.headline)
                    
                    Text("Date: \(formatDate(snapshot.timestamp))")
                        .font(.subheadline)
                    
                    Text("Claims: \(snapshot.claims.count)")
                        .font(.subheadline)
                    
                    Text("Assets: \(snapshot.assets.count)")
                        .font(.subheadline)
                    
                    HStack {
                        Button("Compare with Next") {
                            showingComparison = true
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Close") {
                            selectedSnapshot = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        
        private func snapshotComparisonView(before: MuseeTemporal.MuseSnapshot, after: MuseeTemporal.MuseSnapshot) -> some View {
            VStack {
                Text("Snapshot Comparison")
                    .font(.headline)
                    .padding()
                
                HStack(spacing: 20) {
                    snapshotCard(snapshot: before, title: "Before")
                    snapshotCard(snapshot: after, title: "After")
                }
                .padding()
                
                Spacer()
            }
        }
        
        private func snapshotCard(snapshot: MuseeTemporal.MuseSnapshot, title: String) -> some View {
            MuseumCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(snapshot.timestamp))
                        .font(.caption)
                    
                    Text("\(snapshot.claims.count) claims")
                        .font(.caption)
                    
                    Text("\(snapshot.assets.count) assets")
                        .font(.caption)
                }
            }
            .frame(width: 150)
        }
        
        private func calculatePosition(for date: Date, in width: CGFloat) -> CGFloat {
            guard let first = timeline.snapshots.first?.timestamp,
                  let last = timeline.snapshots.last?.timestamp,
                  first != last else {
                return 0
            }
            
            let totalDuration = last.timeIntervalSince(first)
            let currentDuration = date.timeIntervalSince(first)
            let progress = currentDuration / totalDuration
            
            return max(6, min(width - 6, progress * width))
        }
        
        private func eventIcon(for type: MuseeTemporal.ChangeEvent.ChangeType) -> String {
            switch type {
            case .physicalAppearance: return "person.fill"
            case .health: return "heart.fill"
            case .career: return "briefcase.fill"
            case .lifestyle: return "house.fill"
            case .relationships: return "person.2.fill"
            case .other: return "star.fill"
            }
        }
        
        private func eventColor(for type: MuseeTemporal.ChangeEvent.ChangeType) -> Color {
            switch type {
            case .physicalAppearance: return .blue
            case .health: return .red
            case .career: return .green
            case .lifestyle: return .orange
            case .relationships: return .purple
            case .other: return .gray
            }
        }
        
        private func eventTypeLabel(for type: MuseeTemporal.ChangeEvent.ChangeType) -> String {
            switch type {
            case .physicalAppearance: return "Physical"
            case .health: return "Health"
            case .career: return "Career"
            case .lifestyle: return "Lifestyle"
            case .relationships: return "Relationships"
            case .other: return "Other"
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// A compact timeline view for smaller displays
    struct CompactEvolutionTimeline: View {
        let timeline: MuseeTemporal.EvolutionTimeline
        let evolutionReport: EvolutionReport?
        
        public init(timeline: MuseeTemporal.EvolutionTimeline, evolutionReport: EvolutionReport? = nil) {
            self.timeline = timeline
            self.evolutionReport = evolutionReport
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Evolution")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let report = evolutionReport {
                        Text("\(report.totalChanges) changes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                        
                        // Progress indicator based on evolution magnitude
                        if let report = evolutionReport {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(evolutionColor(for: report.overallMagnitude))
                                .frame(width: geometry.size.width * CGFloat(report.overallMagnitude), height: 4)
                        }
                        
                        // Snapshot markers
                        ForEach(timeline.snapshots.indices, id: \.self) { index in
                            let snapshot = timeline.snapshots[index]
                            let position = calculatePosition(for: snapshot.timestamp, in: geometry.size.width)
                            
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .position(x: position, y: 2)
                        }
                    }
                }
                .frame(height: 8)
                
                // Summary text
                if let report = evolutionReport {
                    Text(report.evolutionPattern)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(timeline.snapshots.count) snapshots tracked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private func calculatePosition(for date: Date, in width: CGFloat) -> CGFloat {
            guard let first = timeline.snapshots.first?.timestamp,
                  let last = timeline.snapshots.last?.timestamp,
                  first != last else {
                return 0
            }
            
            let totalDuration = last.timeIntervalSince(first)
            let currentDuration = date.timeIntervalSince(first)
            let progress = currentDuration / totalDuration
            
            return progress * width
        }
        
        private func evolutionColor(for magnitude: Double) -> Color {
            switch magnitude {
            case 0..<0.3: return .green
            case 0.3..<0.6: return .yellow
            case 0.6..<0.8: return .orange
            default: return .red
            }
        }
    }
}