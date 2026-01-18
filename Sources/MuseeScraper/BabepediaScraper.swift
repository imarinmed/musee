import Foundation
import MuseeCore
import MuseeDomain
// Temporarily using basic parsing until SwiftSoup is resolved
// import SwiftSoup

/// Babepedia scraper implementation
public struct BabepediaScraper: WebScraper {
    private let session: URLSession
    private let rateLimiter: RateLimiter
    private let retryPolicy: RetryPolicy

    public init(session: URLSession = .shared, requestsPerMinute: Double = 30.0) {
        self.session = session
        self.rateLimiter = RateLimiter(requestsPerMinute: requestsPerMinute)
        self.retryPolicy = RetryPolicy(maxRetries: 3, baseDelay: 1.0)
    }

    /// Scrapes model data from a Babepedia profile URL
    public func scrape(from url: URL) async throws -> MuseData {
        guard url.host?.contains("babepedia.com") == true else {
            throw ScrapingError.invalidURL
        }

        let (data, response) = try await performRequest(url: url, method: "GET")

        // Check for anti-scraping measures
        if let html = String(data: data, encoding: .utf8) {
            try detectAntiScrapingMeasures(in: html)
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.encodingError
        }

        return try parseProfile(html: html, baseURL: url)
    }

    /// Scrapes multiple Babepedia URLs concurrently
    public func scrape(from urls: [URL]) async throws -> [MuseData] {
        var results: [MuseData] = []
        for url in urls {
            let result = try await scrape(from: url)
            results.append(result)
        }
        return results
    }

    /// Search for models by name using Babepedia's search functionality
    public func search(query: String, maxResults: Int = 10) async throws -> [URL] {
        let searchURL = URL(string: "https://www.babepedia.com/search/?search_term_string=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
        let (data, _) = try await performRequest(url: searchURL, method: "GET")
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.encodingError
        }

        return try extractSearchResults(from: html, maxResults: maxResults)
    }

    /// Get models from a top list (e.g., top100, pornstartop100)
    public func getTopList(listName: String, maxResults: Int = 100) async throws -> [URL] {
        let listURL = URL(string: "https://www.babepedia.com/\(listName)")!
        let (data, _) = try await performRequest(url: listURL, method: "GET")
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.encodingError
        }

        return try extractListResults(from: html, maxResults: maxResults)
    }

    /// Get models from birthdays page
    public func getTodaysBirthdays(maxResults: Int = 50) async throws -> [URL] {
        let birthdaysURL = URL(string: "https://www.babepedia.com/birthdays")!
        let (data, _) = try await performRequest(url: birthdaysURL, method: "GET")
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScrapingError.encodingError
        }

        return try extractBirthdayResults(from: html, maxResults: maxResults)
    }

    /// Download images from URLs with metadata extraction
    public func downloadImages(from urls: [URL], concurrentLimit: Int = 3) async throws -> [ImageData] {
        var results: [ImageData] = []
        for url in urls {
            do {
                let imageData = try await downloadImage(from: url)
                results.append(imageData)
                // Add a small delay to be respectful
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            } catch {
                // Continue with other downloads
                continue
            }
        }
        return results
    }

    // MARK: - Private Methods

    /// Parses Babepedia profile HTML and extracts structured data
    private func parseProfile(html: String, baseURL: URL) throws -> MuseData {
        // Extract name from title or h1
        let name = extractNameFromString(html: html)

        // Extract bio/description
        let bio = extractBioFromString(html: html)

        // Extract social accounts
        let socialAccounts = extractSocialAccountsFromString(html: html)

        // Extract image URLs
        let mediaURLs = extractImageURLsFromString(html: html, baseURL: baseURL)

        // Extract metadata (measurements, career, etc.)
        let metadata = extractMetadataFromString(html: html)

        return MuseData(
            name: name,
            bio: bio,
            socialAccounts: socialAccounts,
            mediaURLs: mediaURLs,
            metadata: metadata
        )
    }

    private func extractNameFromString(html: String) -> String {
        // Extract from <h1> tag
        if let h1Range = html.range(of: "<h1[^>]*>(.*?)</h1>", options: .regularExpression),
           let name = html[h1Range].split(separator: ">").last?.split(separator: "<").first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return String(name)
        }

        // Extract from <title> tag
        if let titleRange = html.range(of: "<title[^>]*>(.*?)</title>", options: .regularExpression, range: nil, locale: nil),
           let titleContent = html[titleRange].split(separator: ">").last?.split(separator: "<").first,
           let name = titleContent.split(separator: " - ").first?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return String(name)
        }

        return "Unknown Model"
    }

    private func extractBioFromString(html: String) -> String? {
        // Look for bio in common patterns
        let bioPatterns = [
            "<div[^>]*class=\"[^\"]*bio[^\"]*\"[^>]*>(.*?)</div>",
            "<p[^>]*class=\"[^\"]*bio[^\"]*\"[^>]*>(.*?)</p>",
            "<div[^>]*id=\"bio\"[^>]*>(.*?)</div>"
        ]

        for pattern in bioPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let content = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    return content
                }
            }
        }

        return nil
    }

    private func extractSocialAccountsFromString(html: String) -> [SocialAccount] {
        var accounts: [SocialAccount] = []

        // Look for social media URLs
        let socialPatterns = [
            "https?://(?:www\\.)?instagram\\.com/([\\w.]+)",
            "https?://(?:www\\.)?twitter\\.com/([\\w]+)",
            "https?://(?:www\\.)?tiktok\\.com/@([\\w.]+)",
            "https?://(?:www\\.)?youtube\\.com/([\\w]+)"
        ]

        let platformMap = [
            "instagram": "instagram",
            "twitter": "twitter",
            "tiktok": "tiktok",
            "youtube": "youtube"
        ]

        for (index, pattern) in socialPatterns.enumerated() {
            let platform = Array(platformMap.keys)[index]

            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let urlRange = Range(match.range(at: 0), in: html),
               let usernameRange = Range(match.range(at: 1), in: html) {

                let urlString = String(html[urlRange])
                let username = String(html[usernameRange])

                if let url = URL(string: urlString) {
                    accounts.append(SocialAccount(
                        platform: platformMap[platform] ?? "website",
                        username: username,
                        url: url
                    ))
                }
            }
        }

        return accounts
    }

    /// Perform HTTP request with retry logic and rate limiting
    private func performRequest(url: URL, method: String = "GET") async throws -> (Data, URLResponse) {
        // Apply rate limiting
        await rateLimiter.waitIfNeeded()

        // Create request with rotating user agent
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")

        // Execute with retry policy
        return try await retryPolicy.execute {
            let (data, response) = try await session.data(for: request)

            // Check for rate limiting or blocking
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    throw ScrapingError.rateLimited
                } else if httpResponse.statusCode == 403 {
                    throw ScrapingError.accessForbidden
                } else if httpResponse.statusCode == 503 {
                    throw ScrapingError.serviceUnavailable
                }
            }

            return (data, response)
        }
    }

    /// Detect common anti-scraping measures in HTML
    private func detectAntiScrapingMeasures(in html: String) throws {
        let lowerHTML = html.lowercased()

        // Check for CAPTCHA
        if lowerHTML.contains("captcha") || lowerHTML.contains("recaptcha") || lowerHTML.contains("hcaptcha") {
            throw ScrapingError.captchaDetected
        }

        // Check for Cloudflare
        if lowerHTML.contains("cloudflare") || lowerHTML.contains("cf-browser-verification") {
            throw ScrapingError.cloudflareDetected
        }

        // Check for rate limiting messages
        if lowerHTML.contains("rate limit") || lowerHTML.contains("too many requests") {
            throw ScrapingError.rateLimited
        }

        // Check for bot detection
        if lowerHTML.contains("bot detected") || lowerHTML.contains("automated request") {
            throw ScrapingError.botDetected
        }
    }

    /// Get a random user agent string
    private func getRandomUserAgent() -> String {
        let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
        return userAgents.randomElement() ?? userAgents[0]
    }

    private func extractImageURLsFromString(html: String, baseURL: URL) -> [URL] {
        var imageURLs: [URL] = []

        // Profile image pattern - look for larger profile images
        let profilePatterns = [
            "/pics/[^\"]+_thumb3\\.jpg",
            "/pics/[^\"]+_thumb\\.jpg",
            "#profimg[^>]*src=\"([^\"]+)\""
        ]

        for pattern in profilePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) ?? Range(match.range, in: html),
               let url = URL(string: String(html[range]), relativeTo: baseURL)?.absoluteURL {
                if !imageURLs.contains(url) {
                    imageURLs.append(url)
                    break // Take the first good profile image
                }
            }
        }

        // Gallery images (limit to 10 total)
        let imgPattern = "<img[^>]*src=\"([^\"]+(?:jpg|jpeg|png|gif))\"[^>]*alt=\"([^\"]+)\"[^>]*>"
        if let regex = try? NSRegularExpression(pattern: imgPattern, options: []) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if imageURLs.count >= 10 { break }
                if let srcRange = Range(match.range(at: 1), in: html),
                   let url = URL(string: String(html[srcRange]), relativeTo: baseURL)?.absoluteURL,
                   !imageURLs.contains(url) {
                    imageURLs.append(url)
                }
            }
        }

        return imageURLs
    }

    private func extractMetadataFromString(html: String) -> [String: String] {
        var metadata: [String: String] = [:]

        // Extract measurements
        if let measurements = extractMeasurementsFromString(html: html) {
            metadata["measurements"] = measurements
        }

        // Extract height
        if let height = extractHeightFromString(html: html) {
            metadata["height"] = height
        }

        // Extract weight
        if let weight = extractWeightFromString(html: html) {
            metadata["weight"] = weight
        }

        // Extract birthdate
        if let birthdate = extractBirthdateFromString(html: html) {
            metadata["birthdate"] = birthdate
        }

        // Extract career info
        if let career = extractCareerFromString(html: html) {
            metadata["career"] = career
        }

        return metadata
    }

    private func extractMeasurementsFromString(html: String) -> String? {
        // Look for measurement patterns
        let patterns = [
            "(\\d+\\s*-\\s*\\d+\\s*-\\s*\\d+)", // bust-waist-hips
            "(\\d+[^\\d]*\\d+[^\\d]*\\d+)" // with separators
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let match = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !match.isEmpty {
                    return match
                }
            }
        }

        return nil
    }

    private func extractHeightFromString(html: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: "(\\d+\\s*(?:cm|ft|in|'|\")\\w*)", options: []),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let match = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !match.isEmpty {
                return match
            }
        }
        return nil
    }

    private func extractWeightFromString(html: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: "(\\d+\\s*(?:kg|lb|lbs))", options: []),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let match = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !match.isEmpty {
                return match
            }
        }
        return nil
    }

    private func extractBirthdateFromString(html: String) -> String? {
        // Look for birth date patterns
        let patterns = [
            "born\\s+([^<]+)",
            "birth\\s*:\\s*([^<]+)",
            "(\\w+\\s+\\d{1,2},?\\s+\\d{4})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let match = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !match.isEmpty {
                    return match
                }
            }
        }

        return nil
    }

    private func extractCareerFromString(html: String) -> String? {
        // Look for career information
        let patterns = [
            "career\\s*:\\s*([^<]+)",
            "profession\\s*:\\s*([^<]+)",
            "work\\s*:\\s*([^<]+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let match = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !match.isEmpty {
                    return match
                }
            }
        }

        return nil
    }

    private func extractSearchResults(from html: String, maxResults: Int) throws -> [URL] {
        var profileURLs: [URL] = []

        // Look for search result links
        let linkPattern = "<a[^>]*href=\"(/babe/[^\"]+)\"[^>]*>"

        if let regex = try? NSRegularExpression(pattern: linkPattern, options: []) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if profileURLs.count >= maxResults { break }
                if let range = Range(match.range(at: 1), in: html) {
                    let path = String(html[range])
                    if let url = URL(string: "https://www.babepedia.com\(path)") {
                        profileURLs.append(url)
                    }
                }
            }
        }

        return profileURLs
    }

    private func extractListResults(from html: String, maxResults: Int) throws -> [URL] {
        var profileURLs: [URL] = []

        // Look for profile links in lists
        let patterns = [
            "<a[^>]*href=\"(/babe/[^\"]+)\"[^>]*class=\"[^\"]*thumb[^\"]*\"",
            "<a[^>]*href=\"(/babe/[^\"]+)\"[^>]*>.*?</a>"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) {
                let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                for match in matches {
                    if profileURLs.count >= maxResults { break }
                    if let range = Range(match.range(at: 1), in: html) {
                        let path = String(html[range])
                        if let url = URL(string: "https://www.babepedia.com\(path)"),
                           !profileURLs.contains(url) {
                            profileURLs.append(url)
                        }
                    }
                }
            }
            if profileURLs.count >= maxResults { break }
        }

        return profileURLs
    }

    private func extractBirthdayResults(from html: String, maxResults: Int) throws -> [URL] {
        var profileURLs: [URL] = []

        // Look for birthday profile links
        let linkPattern = "<a[^>]*href=\"(/babe/[^\"]+)\"[^>]*>"

        if let regex = try? NSRegularExpression(pattern: linkPattern, options: []) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if profileURLs.count >= maxResults { break }
                if let range = Range(match.range(at: 1), in: html) {
                    let path = String(html[range])
                    if let url = URL(string: "https://www.babepedia.com\(path)") {
                        profileURLs.append(url)
                    }
                }
            }
        }

        return profileURLs
    }

    /// Download a single image with metadata
    private func downloadImage(from url: URL) async throws -> ImageData {
        let (data, response) = try await performRequest(url: url, method: "GET")

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ScrapingError.networkError(URLError(.badServerResponse))
        }

        // Extract metadata from URL or filename
        let filename = url.lastPathComponent
        let altText = extractAltTextFromURL(url)
        let caption = extractCaptionFromURL(url)

        return ImageData(
            url: url,
            data: data,
            filename: filename,
            altText: altText,
            caption: caption,
            contentType: httpResponse.mimeType ?? "image/jpeg"
        )
    }

    private func extractAltTextFromURL(_ url: URL) -> String? {
        // Try to extract meaningful name from URL
        let path = url.path
        if let nameRange = path.range(of: "/([^/]+)\\.[jpg|jpeg|png|gif]", options: .regularExpression) {
            return String(path[nameRange]).replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "_", with: " ")
        }
        return nil
    }

    private func extractCaptionFromURL(_ url: URL) -> String? {
        // Extract from query parameters or path
        if let query = url.query,
           let captionRange = query.range(of: "caption=([^&]+)", options: .regularExpression),
           let caption = query[captionRange].split(separator: "=").last {
            return String(caption).removingPercentEncoding
        }
        return nil
    }

    private func determinePlatform(from url: URL) -> String {
        let host = url.host?.lowercased() ?? ""
        if host.contains("instagram") { return "instagram" }
        if host.contains("twitter") || host.contains("x.com") { return "twitter" }
        if host.contains("tiktok") { return "tiktok" }
        if host.contains("youtube") { return "youtube" }
        return "website"
    }

    private func extractUsername(from url: URL, platform: String) -> String {
        let path = url.path
        switch platform {
        case "instagram":
            return path.split(separator: "/").last?.trimmingCharacters(in: ["/"]) ?? ""
        case "twitter":
            return path.split(separator: "/").last?.trimmingCharacters(in: ["/"]) ?? ""
        case "tiktok":
            return path.split(separator: "/").last?.trimmingCharacters(in: ["/"]) ?? ""
        case "youtube":
            return path.split(separator: "/").last?.trimmingCharacters(in: ["/"]) ?? ""
        default:
            return ""
        }
    }

    /// Downloaded image data with metadata
    public struct ImageData: Sendable {
        public let url: URL
        public let data: Data
        public let filename: String
        public let altText: String?
        public let caption: String?
        public let contentType: String
    }

    /// Async semaphore for rate limiting
    private struct AsyncSemaphore {
        private let semaphore: DispatchSemaphore

        init(value: Int) {
            semaphore = DispatchSemaphore(value: value)
        }

        func wait() async {
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    self.semaphore.wait()
                    continuation.resume()
                }
            }
        }

        func signal() {
            semaphore.signal()
        }
    }

    /// Rate limiter to control request frequency
    private actor RateLimiter {
        private let requestsPerMinute: Double
        private var lastRequestTime: Date

        init(requestsPerMinute: Double) {
            self.requestsPerMinute = requestsPerMinute
            self.lastRequestTime = Date.distantPast
        }

        func waitIfNeeded() async {
            let interval = 60.0 / requestsPerMinute
            let now = Date()

            let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
            let waitTime = max(0, interval - timeSinceLastRequest)

            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }

            lastRequestTime = Date()
        }
    }

    /// Retry policy with exponential backoff
    private struct RetryPolicy {
        let maxRetries: Int
        let baseDelay: TimeInterval

        func execute<T>(_ operation: () async throws -> T) async throws -> T {
            var lastError: Error?

            for attempt in 0...maxRetries {
                do {
                    return try await operation()
                } catch let error as ScrapingError {
                    lastError = error

                    // Don't retry for certain errors
                    switch error {
                    case .invalidURL, .parsingError, .captchaDetected, .accessForbidden:
                        throw error
                    case .rateLimited, .serviceUnavailable, .cloudflareDetected, .botDetected:
                        if attempt < maxRetries {
                            let delay = baseDelay * pow(2.0, Double(attempt))
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        }
                    default:
                        if attempt < maxRetries {
                            let delay = baseDelay * pow(2.0, Double(attempt))
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        }
                    }
                } catch {
                    lastError = error
                    if attempt < maxRetries {
                        let delay = baseDelay * pow(2.0, Double(attempt))
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
            }

            throw lastError ?? ScrapingError.networkError(NSError(domain: "RetryError", code: -1, userInfo: nil))
        }
    }

    enum ScrapingError: Error {
        case invalidURL
        case encodingError
        case parsingError(String)
        case networkError(Error)
        case downloadError(String)
        case rateLimited
        case accessForbidden
        case serviceUnavailable
        case captchaDetected
        case cloudflareDetected
        case botDetected
    }
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}