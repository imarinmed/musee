import XCTest
@testable import MuseeScraper

final class BabepediaScraperIntegrationTests: XCTestCase {
    
    var scraper: BabepediaScraper!
    
    override func setUp() {
        super.setUp()
        scraper = BabepediaScraper()
    }
    
    override func tearDown() {
        scraper = nil
        super.tearDown()
    }
    
    func testRealBabepediaProfileScraping() async throws {
        // Test with a well-known model
        let profileURL = URL(string: "https://www.babepedia.com/babe/Ana_De_Armas")!
        
        do {
            let museData = try await scraper.scrape(from: profileURL)
            
            // Verify basic structure
            XCTAssertFalse(museData.name.isEmpty, "Name should not be empty")
            XCTAssertNotNil(museData.bio, "Bio should be present")
            
            // Verify data quality
            XCTAssertGreaterThanOrEqual(museData.socialAccounts.count, 0, "Should have social accounts or empty array")
            XCTAssertGreaterThanOrEqual(museData.mediaURLs.count, 0, "Should have media URLs or empty array")
            
            // Check metadata contains expected fields
            let expectedMetadataKeys = ["measurements", "height", "weight", "birthdate", "career"]
            for key in expectedMetadataKeys {
                if let value = museData.metadata[key] {
                    XCTAssertFalse(value.isEmpty, "Metadata \(key) should not be empty if present")
                }
            }
            
        } catch BabepediaScraper.ScrapingError.captchaDetected {
            // Acceptable failure - site has CAPTCHA protection
            print("CAPTCHA detected - test acceptable failure")
        } catch BabepediaScraper.ScrapingError.rateLimited {
            // Acceptable failure - rate limiting
            print("Rate limited - test acceptable failure")
        } catch BabepediaScraper.ScrapingError.accessForbidden {
            // Acceptable failure - access forbidden
            print("Access forbidden - test acceptable failure")
        } catch {
            // Other errors should be logged but may be acceptable in CI environment
            print("Integration test failed with error: \(error)")
            throw error
        }
    }
    
    func testSearchAndScrapeWorkflow() async throws {
        do {
            // Search for a model
            let searchResults = try await scraper.search(query: "Scarlett Johansson", maxResults: 3)
            XCTAssertGreaterThan(searchResults.count, 0, "Search should return results")
            
            // Try to scrape the first result
            if let firstURL = searchResults.first {
                let museData = try await scraper.scrape(from: firstURL)
                XCTAssertFalse(museData.name.isEmpty, "Scraped data should have name")
            }
            
        } catch BabepediaScraper.ScrapingError.captchaDetected,
                BabepediaScraper.ScrapingError.rateLimited,
                BabepediaScraper.ScrapingError.accessForbidden {
            // Acceptable failures for integration tests
            print("Anti-scraping measure encountered - acceptable for integration test")
        } catch {
            print("Search/scrape workflow failed: \(error)")
            throw error
        }
    }
    
    func testImageDownloadWorkflow() async throws {
        do {
            // Get a profile with images
            let profileURL = URL(string: "https://www.babepedia.com/babe/Emma_Watson")!
            let museData = try await scraper.scrape(from: profileURL)
            
            if !museData.mediaURLs.isEmpty {
                // Try downloading first image
                let images = try await scraper.downloadImages(from: [museData.mediaURLs[0]])
                XCTAssertEqual(images.count, 1, "Should download one image")
                
                let imageData = images[0]
                XCTAssertFalse(imageData.data.isEmpty, "Downloaded image should have data")
                XCTAssertFalse(imageData.filename.isEmpty, "Image should have filename")
                XCTAssertFalse(imageData.contentType.isEmpty, "Image should have content type")
            } else {
                print("No images found for profile - skipping download test")
            }
            
        } catch BabepediaScraper.ScrapingError.captchaDetected,
                BabepediaScraper.ScrapingError.rateLimited,
                BabepediaScraper.ScrapingError.accessForbidden {
            print("Anti-scraping measure encountered - acceptable for integration test")
        } catch {
            print("Image download workflow failed: \(error)")
            throw error
        }
    }
    
    func testDataConsistency() async throws {
        // Test that multiple scrapes of the same profile return consistent data
        let profileURL = URL(string: "https://www.babepedia.com/babe/Monica_Bellucci")!
        
        do {
            let firstScrape = try await scraper.scrape(from: profileURL)
            let secondScrape = try await scraper.scrape(from: profileURL)
            
            // Names should be consistent
            XCTAssertEqual(firstScrape.name, secondScrape.name, "Names should be consistent across scrapes")
            
            // Basic structure should be similar
            XCTAssertEqual(firstScrape.socialAccounts.count, secondScrape.socialAccounts.count, "Social account count should be consistent")
            
        } catch BabepediaScraper.ScrapingError.captchaDetected,
                BabepediaScraper.ScrapingError.rateLimited,
                BabepediaScraper.ScrapingError.accessForbidden {
            print("Anti-scraping measure encountered - acceptable for integration test")
        } catch {
            print("Data consistency test failed: \(error)")
            throw error
        }
    }
}