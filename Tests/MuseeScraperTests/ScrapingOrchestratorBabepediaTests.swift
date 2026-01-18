import XCTest
@testable import MuseeScraper

final class ScrapingOrchestratorBabepediaTests: XCTestCase {
    
    var orchestrator: ScrapingOrchestrator!
    
    override func setUp() {
        super.setUp()
        orchestrator = ScrapingOrchestrator(
            enableWebScraping: false,
            enableSocialMedia: false,
            enableImageAnalysis: false,
            enableBabepediaScraping: true
        )
    }
    
    override func tearDown() {
        orchestrator = nil
        super.tearDown()
    }
    
    func testBabepediaOnlyConfiguration() {
        XCTAssertFalse(orchestrator.enableWebScraping)
        XCTAssertFalse(orchestrator.enableSocialMedia)
        XCTAssertFalse(orchestrator.enableImageAnalysis)
        XCTAssertTrue(orchestrator.enableBabepediaScraping)
    }
    
    func testBabepediaScrapingByName() async {
        let result = await orchestrator.scrapeMuse(byName: "Ana De Armas")
        
        // Should have babepedia data if successful
        XCTAssertNotNil(result.babepediaData)
        
        // Should not have other data types
        XCTAssertNil(result.webData)
        XCTAssertTrue(result.socialData.isEmpty)
        XCTAssertTrue(result.imageData.isEmpty)
        
        // Should have reasonable scraping duration
        XCTAssertGreaterThan(result.scrapingDuration, 0)
        XCTAssertLessThan(result.scrapingDuration, 30) // Should complete within 30 seconds
    }
    
    func testBabepediaScrapingFromURL() async {
        let babepediaURL = URL(string: "https://www.babepedia.com/babe/Ana_De_Armas")!
        let result = await orchestrator.scrapeMuse(from: babepediaURL)
        
        // Should have babepedia data if successful
        XCTAssertNotNil(result.babepediaData)
        
        // Should not have other data types
        XCTAssertNil(result.webData)
        XCTAssertTrue(result.socialData.isEmpty)
        XCTAssertTrue(result.imageData.isEmpty)
    }
    
    func testScrapingResultStructure() async {
        let result = await orchestrator.scrapeMuse(byName: "Test Model")
        
        // Result should have all expected properties
        XCTAssertNotNil(result.babepediaData)
        XCTAssertTrue(result.socialData.isEmpty)
        XCTAssertTrue(result.imageData.isEmpty)
        XCTAssertGreaterThanOrEqual(result.scrapingDuration, 0)
        
        // Babepedia data should have expected structure
        if let babepediaData = result.babepediaData {
            XCTAssertFalse(babepediaData.name.isEmpty)
            XCTAssertGreaterThanOrEqual(babepediaData.socialAccounts.count, 0)
            XCTAssertGreaterThanOrEqual(babepediaData.mediaURLs.count, 0)
            XCTAssertGreaterThanOrEqual(babepediaData.metadata.count, 0)
        }
    }
    
    func testErrorHandling() async {
        // Test with invalid name that should fail gracefully
        let result = await orchestrator.scrapeMuse(byName: "NonExistentModel12345")
        
        // Should still return a result, even if with errors
        XCTAssertNotNil(result)
        
        // If there are errors, they should be properly categorized
        for error in result.errors {
            XCTAssertFalse(error.source.isEmpty)
            XCTAssertNotNil(error.error)
            XCTAssertGreaterThanOrEqual(error.timestamp, Date.distantPast)
        }
    }
    
    func testDisabledBabepediaScraping() {
        let disabledOrchestrator = ScrapingOrchestrator(
            enableBabepediaScraping: false
        )
        
        XCTAssertFalse(disabledOrchestrator.enableBabepediaScraping)
    }
}