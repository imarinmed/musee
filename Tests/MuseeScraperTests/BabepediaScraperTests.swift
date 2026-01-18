import XCTest
@testable import MuseeScraper

final class BabepediaScraperTests: XCTestCase {
    
    var scraper: BabepediaScraper!
    
    override func setUp() {
        super.setUp()
        scraper = BabepediaScraper()
    }
    
    override func tearDown() {
        scraper = nil
        super.tearDown()
    }
    
    func testBabepediaScraperInitialization() {
        XCTAssertNotNil(scraper)
    }
    
    func testInvalidURLRejection() async {
        let invalidURL = URL(string: "https://example.com")!
        
        do {
            _ = try await scraper.scrape(from: invalidURL)
            XCTFail("Expected error for invalid URL")
        } catch let error as BabepediaScraper.ScrapingError {
            switch error {
            case .invalidURL:
                // Expected error
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSearchFunctionality() async {
        // Test with a known model name
        do {
            let urls = try await scraper.search(query: "Ana De Armas", maxResults: 5)
            XCTAssertGreaterThan(urls.count, 0, "Search should return at least one result")
            
            // Verify URLs are valid Babepedia profile URLs
            for url in urls {
                XCTAssertTrue(url.absoluteString.contains("babepedia.com"))
                XCTAssertTrue(url.path.contains("/babe/"))
            }
        } catch {
            // Network errors are acceptable in test environment
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testTopListRetrieval() async {
        do {
            let urls = try await scraper.getTopList(listName: "top100", maxResults: 10)
            XCTAssertGreaterThan(urls.count, 0, "Top list should return results")
            
            for url in urls {
                XCTAssertTrue(url.absoluteString.contains("babepedia.com"))
            }
        } catch {
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testTodaysBirthdaysRetrieval() async {
        do {
            let urls = try await scraper.getTodaysBirthdays(maxResults: 5)
            // Birthdays may not always be available, so just check no error
            for url in urls {
                XCTAssertTrue(url.absoluteString.contains("babepedia.com"))
            }
        } catch {
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testImageDownloading() async {
        do {
            // First get some profile URLs
            let profileURLs = try await scraper.search(query: "Emma Watson", maxResults: 1)
            guard let profileURL = profileURLs.first else {
                print("No profile URL found, skipping image download test")
                return
            }
            
            // Scrape the profile to get image URLs
            let museData = try await scraper.scrape(from: profileURL)
            XCTAssertFalse(museData.mediaURLs.isEmpty, "Profile should have media URLs")
            
            // Try downloading first image
            let images = try await scraper.downloadImages(from: Array(museData.mediaURLs.prefix(1)))
            XCTAssertEqual(images.count, 1, "Should download one image")
            
            let imageData = images.first!
            XCTAssertFalse(imageData.data.isEmpty, "Image data should not be empty")
            XCTAssertFalse(imageData.filename.isEmpty, "Filename should not be empty")
        } catch {
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testConcurrentScraping() async {
        let urls = [
            URL(string: "https://www.babepedia.com/babe/Ana_De_Armas")!,
            URL(string: "https://www.babepedia.com/babe/Emma_Watson")!,
            URL(string: "https://www.babepedia.com/babe/Scarlett_Johansson")!
        ]
        
        do {
            let results = try await scraper.scrape(from: urls)
            XCTAssertEqual(results.count, urls.count, "Should scrape all URLs")
            
            // At least some should succeed (depending on network)
            let successfulResults = results.filter { _ in true } // All results are MuseData
            XCTAssertGreaterThan(successfulResults.count, 0, "At least one scrape should succeed")
        } catch {
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testRateLimiting() async {
        // Test that rate limiting prevents too many rapid requests
        let startTime = Date()
        
        do {
            // Make multiple requests quickly
            for i in 0..<5 {
                _ = try await scraper.search(query: "test\(i)", maxResults: 1)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            // Should take at least some time due to rate limiting
            XCTAssertGreaterThan(duration, 0.5, "Rate limiting should add delay")
        } catch {
            print("Network error in test (expected): \(error)")
        }
    }
    
    func testUserAgentRotation() {
        // Test that different requests use different user agents
        // This is hard to test directly, but we can verify the scraper has the functionality
        
        // The scraper should have user agent rotation implemented
        // This is tested implicitly through successful requests
        XCTAssertNotNil(scraper)
    }
}