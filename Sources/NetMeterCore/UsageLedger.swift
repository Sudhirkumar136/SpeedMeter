import Foundation

public enum UsagePeriod: String, CaseIterable, Sendable {
    case today
    case yesterday
    case lastSevenDays
    case thisMonth
    case previousMonth

    public var title: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .lastSevenDays: "Last 7 Days"
        case .thisMonth: "This Month"
        case .previousMonth: "Previous Month"
        }
    }
}

public struct DailyUsage: Equatable, Identifiable, Sendable {
    public let day: String
    public let totals: TrafficTotals
    public var id: String { day }
}

public struct UsageLedger: Codable, Equatable, Sendable {
    private var days: [String: TrafficTotals]

    public init(days: [String: TrafficTotals] = [:]) {
        self.days = days
    }

    public var dailyRows: [DailyUsage] {
        days.map { DailyUsage(day: $0.key, totals: $0.value) }
            .sorted { $0.day > $1.day }
    }

    public mutating func record(_ delta: TrafficDelta, on date: Date, calendar: Calendar = .current) {
        let key = Self.dayKey(date, calendar: calendar)
        var totals = days[key] ?? .zero
        totals.add(delta)
        days[key] = totals
    }

    public func totals(
        for period: UsagePeriod,
        relativeTo date: Date,
        calendar: Calendar = .current
    ) -> TrafficTotals {
        let day = calendar.startOfDay(for: date)
        let start: Date
        let end: Date
        switch period {
        case .today:
            start = day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return .zero }
            end = nextDay
        case .yesterday:
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { return .zero }
            start = previousDay
            end = day
        case .lastSevenDays:
            guard let firstDay = calendar.date(byAdding: .day, value: -6, to: day),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day)
            else { return .zero }
            start = firstDay
            end = nextDay
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: day) else { return .zero }
            start = interval.start
            end = interval.end
        case .previousMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: day),
                  let interval = calendar.dateInterval(of: .month, for: lastMonth)
            else { return .zero }
            start = interval.start
            end = interval.end
        }
        let first = Self.dayKey(start, calendar: calendar)
        let afterLast = Self.dayKey(end, calendar: calendar)
        return days.reduce(into: TrafficTotals.zero) { result, item in
            if item.key >= first && item.key < afterLast {
                result.add(TrafficDelta(received: item.value.downloaded, sent: item.value.uploaded))
            }
        }
    }

    public mutating func resetToday(relativeTo date: Date, calendar: Calendar = .current) {
        days.removeValue(forKey: Self.dayKey(date, calendar: calendar))
    }

    public mutating func resetAll() {
        days.removeAll()
    }

    public mutating func prune(keepingLast count: Int, relativeTo date: Date, calendar: Calendar = .current) {
        guard count > 0,
              let firstDate = calendar.date(byAdding: .day, value: -(count - 1), to: calendar.startOfDay(for: date))
        else { return }
        let first = Self.dayKey(firstDate, calendar: calendar)
        days = days.filter { $0.key >= first }
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
