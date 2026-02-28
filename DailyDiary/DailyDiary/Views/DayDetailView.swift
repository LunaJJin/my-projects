import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allEntries: [DiaryEntry]

    let date: Date

    @State private var showEditor = false
    @State private var editingEntry: DiaryEntry? = nil
    @State private var showDeleteAlert = false
    @State private var entryToDelete: DiaryEntry? = nil
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0
    @State private var viewerPhotos: [Data] = []

    private var entries: [DiaryEntry] {
        allEntries
            .filter { $0.dateKey == date.dateKey }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var canAddMore: Bool {
        entries.count < 3
    }

    var body: some View {
        ZStack {
            LinearGradient.pastelBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    dateHeader
                    entriesSection
                    if canAddMore {
                        addButton
                    } else {
                        maxEntriesNotice
                    }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("달력")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.pastelPink)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            DiaryEditorView(date: date, existingEntry: editingEntry)
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            PhotoViewerView(photos: viewerPhotos, currentIndex: selectedPhotoIndex)
        }
        .alert("일기 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let entry = entryToDelete {
                    withAnimation {
                        modelContext.delete(entry)
                    }
                }
            }
        } message: {
            Text("이 일기를 정말 삭제할까요?\n삭제하면 되돌릴 수 없어요.")
        }
    }

    // MARK: - Date Header
    private var dateHeader: some View {
        VStack(spacing: 6) {
            Text(date.koreanFullDateString)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)

            HStack(spacing: 8) {
                ForEach(entries) { entry in
                    Text(entry.stickerEmoji)
                        .font(.system(size: 24))
                }
            }

            Text("일기 \(entries.count)/3")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.diaryTextLight)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Entries
    private var entriesSection: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                emptyState
            } else {
                ForEach(entries) { entry in
                    diaryCard(entry: entry)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 50))

            Text("아직 일기가 없어요")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)

            Text("오늘 하루는 어땠나요?\n첫 번째 일기를 써보세요!")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.diaryTextLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.withOpacity(0.85))
                .shadow(color: .cardShadow, radius: 15, x: 0, y: 8)
        )
    }

    private func diaryCard(entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sticker & time
            HStack {
                Text(entry.stickerEmoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString(from: entry.createdAt))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.diaryTextLight)

                    if entry.updatedAt.timeIntervalSince(entry.createdAt) > 60 {
                        Text("수정됨")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.diaryTextMuted)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        editingEntry = entry
                        showEditor = true
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        entryToDelete = entry
                        showDeleteAlert = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.diaryTextLight)
                        .frame(width: 32, height: 32)
                        .background(Color.pastelPinkLight.withOpacity(0.5))
                        .clipShape(Circle())
                }
            }

            // Content
            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.diaryText)
                    .lineSpacing(4)
            }

            // Photos
            if !entry.photoDataArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.photoDataArray.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: entry.photoDataArray[index]) {
                                Button {
                                    selectedPhotoIndex = index
                                    viewerPhotos = entry.photoDataArray
                                    showPhotoViewer = true
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.withOpacity(0.85))
                .shadow(color: .cardShadow, radius: 15, x: 0, y: 8)
        )
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            editingEntry = nil
            showEditor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("새 일기 쓰기")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(LinearGradient.pastelHeader)
                    .shadow(color: .cardShadow, radius: 10, x: 0, y: 5)
            )
        }
    }

    private var maxEntriesNotice: some View {
        HStack(spacing: 8) {
            Text("✨")
                .font(.system(size: 16))
            Text("오늘의 일기를 모두 작성했어요!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.diaryTextLight)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(Color.pastelYellow.withOpacity(0.5))
        )
    }

    // MARK: - Helpers
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        DayDetailView(date: Date())
    }
    .modelContainer(for: DiaryEntry.self, inMemory: true)
}
