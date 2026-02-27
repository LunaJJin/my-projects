import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.createdAt, order: .descending) private var allEntries: [DiaryEntry]

    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showDayDetail = false

    private var entriesByDateKey: [String: [DiaryEntry]] {
        Dictionary(grouping: allEntries, by: \.dateKey)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.pastelBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        calendarCard
                        if let selectedDate = selectedDate {
                            selectedDatePreview(for: selectedDate)
                        }
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationDestination(isPresented: $showDayDetail) {
                if let date = selectedDate {
                    DayDetailView(date: date)
                }
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 4) {
            Text("My Daily Diary")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)

            Text("오늘의 이야기를 기록해보세요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.diaryTextLight)
        }
        .padding(.top, 10)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 16) {
            monthNavigator
            weekdayHeader
            calendarGrid
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .cardShadow, radius: 15, x: 0, y: 8)
        )
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    currentMonth = currentMonth.adding(months: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pastelPink)
                    .frame(width: 36, height: 36)
                    .background(Color.pastelPinkLight)
                    .clipShape(Circle())
            }

            Spacer()

            Text(currentMonth.koreanMonthString)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    currentMonth = currentMonth.adding(months: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pastelPink)
                    .frame(width: 36, height: 36)
                    .background(Color.pastelPinkLight)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        return HStack(spacing: 0) {
            ForEach(weekdays.indices, id: \.self) { index in
                Text(weekdays[index])
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        index == 0 ? Color.red.opacity(0.6) :
                        index == 6 ? Color.blue.opacity(0.5) :
                        .diaryTextLight
                    )
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let daysInMonth = currentMonth.numberOfDaysInMonth
        let firstWeekday = currentMonth.firstWeekdayOfMonth
        let leadingSpaces = firstWeekday - 1
        let totalCells = leadingSpaces + daysInMonth
        let rows = (totalCells + 6) / 7

        return VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let dayNumber = index - leadingSpaces + 1

                        if dayNumber >= 1 && dayNumber <= daysInMonth {
                            calendarDayCell(day: dayNumber, weekday: col)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Cell
    private func calendarDayCell(day: Int, weekday: Int) -> some View {
        let date = currentMonth.dayDate(day: day) ?? Date()
        let dateKey = date.dateKey
        let entries = entriesByDateKey[dateKey] ?? []
        let hasEntries = !entries.isEmpty
        let isSelected = selectedDate?.dateKey == dateKey
        let isToday = date.isToday

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 15, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        weekday == 0 ? Color.red.opacity(0.7) :
                        weekday == 6 ? Color.blue.opacity(0.6) :
                        .diaryText
                    )

                if hasEntries {
                    Text(entries.first?.stickerEmoji ?? "🌸")
                        .font(.system(size: 12))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear.frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.pastelPink, Color.pastelLavender],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pastelYellow.opacity(0.5))
                    } else if hasEntries {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pastelPinkLight.opacity(0.5))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Date Preview
    private func selectedDatePreview(for date: Date) -> some View {
        let dateKey = date.dateKey
        let entries = entriesByDateKey[dateKey] ?? []

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.koreanFullDateString)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.diaryText)

                    Text(entries.isEmpty ? "아직 일기가 없어요" : "일기 \(entries.count)개")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.diaryTextLight)
                }

                Spacer()

                Button {
                    showDayDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: entries.isEmpty ? "pencil" : "book")
                            .font(.system(size: 14))
                        Text(entries.isEmpty ? "일기 쓰기" : "보기")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(LinearGradient.pastelHeader)
                    )
                    .shadow(color: .cardShadow, radius: 5, x: 0, y: 3)
                }
            }

            if !entries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(entries.prefix(2)) { entry in
                        HStack(spacing: 10) {
                            Text(entry.stickerEmoji)
                                .font(.system(size: 20))

                            Text(entry.content.isEmpty ? "내용 없음" : entry.content)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.diaryText)
                                .lineLimit(1)

                            Spacer()

                            if !entry.photoDataArray.isEmpty {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                    .foregroundColor(.diaryTextMuted)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pastelPinkLight.opacity(0.4))
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .cardShadow, radius: 15, x: 0, y: 8)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
