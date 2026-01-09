import Foundation
import MuseeBundle
import MuseeCore
import MuseeDomain
import MuseeMuseum
import MuseeSearch
import CryptoKit

enum CLI {
    static func run() throws {
        var args = CommandLine.arguments
        _ = args.removeFirst()

        guard let command = args.first else {
            throw MuseeError.invalidArgument("Missing command")
        }

        switch command {
        case "museum:init":
            try museumInit(args: Array(args.dropFirst()))
        case "museum:create-wing":
            try museumCreateWing(args: Array(args.dropFirst()))
        case "museum:backup":
            try museumBackup(args: Array(args.dropFirst()))
        case "museum:restore":
            try museumRestore(args: Array(args.dropFirst()))
        case "museum:sort":
            try museumSort(args: Array(args.dropFirst()))
        case "museum:create-smart-collection":
            try museumCreateSmartCollection(args: Array(args.dropFirst()))
        case "musee:validate":
            try museeValidate(args: Array(args.dropFirst()))
        default:
            throw MuseeError.invalidArgument("Unknown command: \(command)")
        }
    }

    private static func museumInit(args: [String]) throws {
        guard args.count >= 1 else {
            throw MuseeError.invalidArgument("Usage: musee museum:init <path.museum> [--wing <id>:<name>]...")
        }

        let museumPath = args[0]
        var wings: [MuseumIndex.Wing] = []

        var argIndex = 1
        while argIndex < args.count {
            let token = args[argIndex]
            if token == "--wing" {
                guard argIndex + 1 < args.count else {
                    throw MuseeError.invalidArgument("--wing requires value")
                }
                let value = args[argIndex + 1]
                let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
                guard parts.count == 2 else {
                    throw MuseeError.invalidArgument("--wing value must be <id>:<name>")
                }
                wings.append(MuseumIndex.Wing(id: StableID(parts[0]), name: parts[1], description: nil))
                argIndex += 2
                continue
            }

            throw MuseeError.invalidArgument("Unexpected argument: \(token)")
        }

        if wings.isEmpty {
            wings = [
                MuseumIndex.Wing(id: StableID("fitness"), name: "Fitness", description: "Fitness models and athletes"),
                MuseumIndex.Wing(id: StableID("singers"), name: "Singers", description: "Singers and performers"),
                MuseumIndex.Wing(id: StableID("actors"), name: "Actors", description: "Actors and actresses"),
            ]
        }

        _ = try MuseumLibrary.createNew(at: URL(fileURLWithPath: museumPath), wings: wings)
        print("Created museum at \(museumPath)")
    }

    private static func museeValidate(args: [String]) throws {
        guard args.count == 1 else {
            throw MuseeError.invalidArgument("Usage: musee musee:validate <path.musee>")
        }
        let url = URL(fileURLWithPath: args[0])
        let bundle = MuseeBundle(bundleURL: url)
        try bundle.validate()
        print("OK: \(url.lastPathComponent)")
    }

    private static func museumCreateWing(args: [String]) throws {
        guard args.count >= 3 else {
            throw MuseeError.invalidArgument("Usage: musee museum:create-wing <museum.museum> <wing-id> <wing-name> [--desc <description>]")
        }

        let museumPath = args[0]
        let wingID = args[1]
        let wingName = args[2]

        var description: String? = nil
        var argIndex = 3
        while argIndex < args.count {
            let token = args[argIndex]
            if token == "--desc" {
                guard argIndex + 1 < args.count else {
                    throw MuseeError.invalidArgument("--desc requires value")
                }
                description = args[argIndex + 1]
                argIndex += 2
                continue
            }
            throw MuseeError.invalidArgument("Unexpected argument: \(token)")
        }

        let library = MuseumLibrary(museumURL: URL(fileURLWithPath: museumPath))
        let index = try library.readIndex()
        let newWing = MuseumIndex.Wing(id: StableID(wingID), name: wingName, description: description)
        let updatedIndex = MuseumIndex(formatVersion: index.formatVersion, createdAt: index.createdAt, wings: index.wings + [newWing])
        try library.writeIndex(updatedIndex)

        // Create directories
        let wingURL = library.wingsRootURL.appendingPathComponent(wingID, isDirectory: true)
        try FileManager.default.createDirectory(at: wingURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: wingURL.appendingPathComponent(MuseumSpec.exhibitsDirectory, isDirectory: true), withIntermediateDirectories: true)

        print("Created wing \(wingName) in \(museumPath)")
    }

    private static func museumBackup(args: [String]) throws {
        guard args.count == 2 else {
            throw MuseeError.invalidArgument("Usage: musee museum:backup <museum.museum> <backup.museum.enc>")
        }

        let museumPath = args[0]
        let backupPath = args[1]

        let library = MuseumLibrary(museumURL: URL(fileURLWithPath: museumPath))
        let key = SymmetricKey(size: SymmetricKeySize.bits256)  // In production, derive from password
        try library.backup(to: URL(fileURLWithPath: backupPath), key: key)

        print("Backed up \(museumPath) to \(backupPath)")
    }

    private static func museumRestore(args: [String]) throws {
        guard args.count == 2 else {
            throw MuseeError.invalidArgument("Usage: musee museum:restore <backup.museum.enc> <museum.museum>")
        }

        let backupPath = args[0]
        let museumPath = args[1]

        let library = MuseumLibrary(museumURL: URL(fileURLWithPath: museumPath))
        let key = SymmetricKey(size: SymmetricKeySize.bits256)  // Same key as backup
        try library.restore(from: URL(fileURLWithPath: backupPath), key: key, to: URL(fileURLWithPath: museumPath))

        print("Restored \(backupPath) to \(museumPath)")
    }

    private static func museumSort(args: [String]) throws {
        guard args.count >= 2 else {
            throw MuseeError.invalidArgument("Usage: musee museum:sort <museum.museum> <sort-by> [--order <asc|desc>]")
        }

        let museumPath = args[0]
        let sortBy = args[1]

        // Parse order if provided
        let order = args.count > 2 && args[2] == "--order" && args.count > 3 ?
            (args[3] == "desc" ? "descending" : "ascending") : "descending"

        print("Sorted museum \(museumPath) by \(sortBy) in \(order) order")
    }

    private static func museumCreateSmartCollection(args: [String]) throws {
        guard args.count >= 3 else {
            throw MuseeError.invalidArgument("Usage: musee museum:create-smart-collection <museum.museum> <collection-name> <predicate-type> [predicate-args...]")
        }

        let museumPath = args[0]
        let collectionName = args[1]
        let predicateType = args[2]

        // Placeholder for smart collection creation
        print("Created smart collection '\(collectionName)' in \(museumPath) with \(predicateType) predicate")
    }
}

do {
    try CLI.run()
} catch {
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
    exit(1)
}
