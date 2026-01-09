# Cloud Sync

Musee supports cross-device synchronization using CloudKit for seamless access to museums and bundles across Apple devices.

## CloudKit Integration

- **Container Setup**: Private CloudKit database for user data
- **Record Types**: Museum, Bundle, Claim, Tag synchronization
- **Conflict Resolution**: Automatic merging of concurrent changes
- **Offline Support**: Local-first architecture with sync when online

## Sync Process

```swift
func syncMuseum(_ museum: MuseumLibrary) async throws {
    let container = CKContainer(identifier: "com.example.musee")
    let database = container.privateCloudDatabase

    // Upload local changes
    try await uploadPendingChanges(to: database)

    // Download remote changes
    let remoteChanges = try await fetchRemoteChanges(from: database)

    // Merge conflicts
    try await resolveConflicts(local: museum, remote: remoteChanges)
}
```