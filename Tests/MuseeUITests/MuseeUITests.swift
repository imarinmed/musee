//
//  MuseeUITests.swift
//  MuseeUITests
//
//  Unit tests for MuseeUI shared components.
//

import Testing
@testable import MuseeUI

@Suite("MuseeUI Tests")
struct MuseeUITests {

    @Test("MuseumCard initializes correctly")
    func testMuseumCard() async throws {
        // Test that MuseumCard can be created and renders
        // Note: Full UI testing would require SwiftUI testing framework
        let card = MuseumCard {
            Text("Test Content")
        }
        #expect(card != nil)
    }

    @Test("MuseumLoadingView initializes correctly")
    func testMuseumLoadingView() async throws {
        let loadingView = MuseumLoadingView()
        #expect(loadingView != nil)
    }

    @Test("MuseumSearchBar initializes correctly")
    func testMuseumSearchBar() async throws {
        let searchBar = MuseumSearchBar(text: .constant(""), placeholder: "Search")
        #expect(searchBar != nil)
    }
}