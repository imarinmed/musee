//
//  MuseePlatformMacTests.swift
//  MuseePlatformMacTests
//
//  Unit tests for MuseePlatformMac macOS implementations.
//

import Testing
@testable import MuseePlatformMac

@Suite("MuseePlatformMac Tests")
struct MuseePlatformMacTests {

    @Test("MacOSImagePicker initializes correctly")
    func testMacOSImagePicker() async throws {
        let picker = MacOSImagePicker()
        #expect(picker != nil)
    }

    @Test("MacOSFileManager initializes correctly")
    func testMacOSFileManager() async throws {
        let fileManager = MacOSFileManager()
        #expect(fileManager != nil)
    }

    @Test("BlurWindow initializes correctly")
    func testBlurWindow() async throws {
        let blurWindow = BlurWindow()
        #expect(blurWindow != nil)
    }
}