import Foundation

extension Date {
    private static let koreaTimeZone = TimeZone(identifier: "Asia/Seoul")!

    private static var koreanCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "ko_KR")
        cal.timeZone = koreaTimeZone
        cal.firstWeekday = 1 // Sunday
        return cal
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Self.koreaTimeZone
        return formatter.string(from: self)
    }

    var year: Int {
        Self.koreanCalendar.component(.year, from: self)
    }

    var month: Int {
        Self.koreanCalendar.component(.month, from: self)
    }

    var day: Int {
        Self.koreanCalendar.component(.day, from: self)
    }

    var weekday: Int {
        Self.koreanCalendar.component(.weekday, from: self)
    }

    var startOfMonth: Date {
        let components = Self.koreanCalendar.dateComponents([.year, .month], from: self)
        return Self.koreanCalendar.date(from: components)!
    }

    var endOfMonth: Date {
        Self.koreanCalendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }

    var numberOfDaysInMonth: Int {
        Self.koreanCalendar.range(of: .day, in: .month, for: self)!.count
    }

    var firstWeekdayOfMonth: Int {
        startOfMonth.weekday
    }

    func isSameDay(as other: Date) -> Bool {
        Self.koreanCalendar.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool {
        Self.koreanCalendar.isDateInToday(self)
    }

    func adding(months: Int) -> Date {
        Self.koreanCalendar.date(byAdding: .month, value: months, to: self)!
    }

    func dayDate(day: Int) -> Date? {
        var components = Self.koreanCalendar.dateComponents([.year, .month], from: self)
        components.day = day
        return Self.koreanCalendar.date(from: components)
    }

    var koreanMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = Self.koreaTimeZone
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: self)
    }

    var koreanFullDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = Self.koreaTimeZone
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: self)
    }

    var koreanShortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = Self.koreaTimeZone
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: self)
    }

    static func fromDateKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = koreaTimeZone
        return formatter.date(from: key)
    }
}
