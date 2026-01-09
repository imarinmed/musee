# Musee

Musee is a comprehensive Swift framework for curating audiovisual content and metadata about persons of interest, with advanced AI-powered beauty analysis and longitudinal tracking.

## Overview

Musee enables the creation of digital museums that preserve and analyze the visual evolution of individuals over time. It combines sophisticated metadata extraction, AI-driven beauty scoring (EROSS), and powerful search capabilities to provide unprecedented insights into personal aesthetics and history.

Musee is built with a modular architecture consisting of 8 core modules: MuseeCore (utilities), MuseeDomain (data models), MuseeCAS (content storage), MuseeBundle (.musee format), MuseeMuseum (.museum organization), MuseeMetadata (extraction), MuseeSearch (queries), and MuseeVision (AI processing).

## Key Features

### EROSS Beauty Analysis System
- **Comprehensive Facial Analysis**: 16+ metrics including golden ratio, neoclassical canons, facial thirds, eye/nose/mouth proportions
- **Advanced Skin Assessment**: Texture, tone, radiance, undertone analysis using 2025 dermatological AI methods
- **Symmetry Detection**: Bilateral facial and body symmetry with sub-feature analysis (eyes, nose, mouth)
- **Feature Assessment**: Detailed eye, nose, mouth, and facial structure analysis with cultural adaptations
- **Time Evolution**: Longitudinal beauty tracking with trend analysis and peak/valley detection
- **Research-Backed Scoring**: Calibrated against 2026 cross-cultural attractiveness studies

### Museum Architecture
- **Bundle Format**: .musee files containing media, metadata, and AI analysis
- **Museum Organization**: .museum libraries with wings (categories) and exhibits
- **Content-Addressed Storage**: SHA-256 based immutable asset storage
- **Hierarchical Structure**: Nested collections and smart curation

### AI Vision Processing
- **Face Detection**: 68-point facial landmark detection
- **Pose Estimation**: Human body pose analysis for measurements
- **Perceptual Hashing**: aHash/dHash for image similarity and deduplication
- **Auto-Tagging**: Vision-based classification for clothing, hair, accessories
- **Beauty Feature Extraction**: Comprehensive aesthetic analysis

### Metadata & Provenance
- **EXIF/IPTC/XMP Extraction**: Standard metadata parsing
- **C2PA Verification**: Content authenticity and provenance
- **Claims System**: Attributed assertions with confidence and references
- **Immutable History**: Cryptographic provenance for all data

### Search & Discovery
- **Faceted Search**: Multi-dimensional filtering by person, tags, dates, beauty scores
- **AI-Enhanced Queries**: Natural language search with ML understanding
- **Smart Collections**: Auto-curated collections based on rules and AI
- **Vector Search**: Similarity-based discovery using perceptual hashes

### Cloud & Collaboration
- **CloudKit Sync**: Cross-device synchronization
- **Encrypted Backup**: AES-GCM encrypted museum archives
- **Multi-User Support**: Shared museums with access controls
- **Conflict Resolution**: Automatic merge strategies for concurrent edits

### CLI & Automation
- **Command Line Interface**: Full museum management from terminal
- **Batch Processing**: Automated media ingestion and analysis
- **Export Capabilities**: PDF reports, JSON data dumps, media archives
- **Integration APIs**: RESTful interfaces for third-party tools

## Architecture Modules

### MuseeCore
Foundation utilities including error handling, stable IDs, and partial dates.

### MuseeDomain
Core data models: Person, MediaAsset, BiographicalClaim, Tag, Platform.

### MuseeCAS
Content-addressed storage with SHA-256 hashing and sharded directories.

### MuseeBundle
.musee bundle format handling with manifest and Objects/ structure.

### MuseeMuseum
.museum library management with wings, exhibits, and organization.

### MuseeMetadata
Metadata extraction from EXIF, IPTC, XMP, and C2PA verification.

### MuseeSearch
Faceted search engine with in-memory and potential database backends.

### MuseeVision
AI vision processing including Vision framework integration and EROSS calculations.

## Concepts

### Stable IDs
Cryptographically secure UUIDs ensuring global uniqueness across systems.

### Partial Dates
Flexible date representation supporting year-only, month-year, or full dates.

### Biographical Claims
Attributed assertions about persons with confidence levels and provenance references.

### Content Provenance
Immutable audit trails for all media and metadata using cryptographic methods.

### Golden Ratio (φ)
Mathematical proportion (1.618) used in classical beauty analysis and facial harmony assessment.

## Topics

### Getting Started
- <doc:Installation>
- <doc:QuickStart>
- <doc:BasicMuseumSetup>

### Guides
- <doc:BeautyAnalysisGuide>
- <doc:AdvancedSearchTutorial>
- <doc:BackupAndSyncGuide>
- <doc:CustomizingMuseums>
- <doc:EROSSTimeTracking>
- <doc:UnderstandingBeautyMetrics>

### Core Concepts
- <doc:MuseumArchitecture>
- <doc:EROSSSystem>
- <doc:MetadataExtraction>
- <doc:ClaimsAndProvenance>
- <doc:AIProcessing>

### Advanced Features
- <doc:SearchAndDiscovery>
- <doc:CloudSync>
- <doc:SecurityAndPrivacy>

### API Reference
- <doc:MuseeCore>
- <doc:MuseeDomain>
- <doc:MuseeVision>
- <doc:MuseeSearch>
- <doc:MuseeBundle>
- <doc:MuseeMuseum>
- <doc:MuseeMetadata>
- <doc:MuseeCLI>

### Reference
- <doc:CLIReference>
- <doc:Troubleshooting>
- <doc:Changelog>