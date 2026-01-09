import Foundation

public struct SortableDateKey: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: SortableDateKey, rhs: SortableDateKey) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.day < rhs.day
    }
}

public struct PartialDate: Hashable, Codable, Sendable, Comparable {
    public enum Precision: String, Codable, Sendable {
        case year
        case month
        case day
        case unknown
    }

    public let year: Int?
    public let month: Int?
    public let day: Int?
    public let precision: Precision

    public init(year: Int?, month: Int?, day: Int?, precision: Precision) {
        self.year = year
        self.month = month
        self.day = day
        self.precision = precision
    }

    public static func year(_ year: Int) -> PartialDate {
        PartialDate(year: year, month: nil, day: nil, precision: .year)
    }

    public static func month(year: Int, month: Int) -> PartialDate {
        PartialDate(year: year, month: month, day: nil, precision: .month)
    }

    public static func day(year: Int, month: Int, day: Int) -> PartialDate {
        PartialDate(year: year, month: month, day: day, precision: .day)
    }

    public var sortKey: SortableDateKey {
        SortableDateKey(
            year: year ?? Int.min,
            month: month ?? Int.min,
            day: day ?? Int.min
        )
    }

    public static func < (lhs: PartialDate, rhs: PartialDate) -> Bool {
        lhs.sortKey < rhs.sortKey
    }

    public var description: String {
        switch precision {
        case .year:
            return year.map { "\($0)" } ?? "Unknown"
        case .month:
            if let year = year, let month = month {
                return String(format: "%04d-%02d", year, month)
            }
            return "Unknown"
        case .day:
            if let year = year, let month = month, let day = day {
                return String(format: "%04d-%02d-%02d", year, month, day)
            }
            return "Unknown"
        case .unknown:
            return "Unknown"
        }
    }
}
