import SwiftUI
import SwiftData
import PhotosUI

struct DiaryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let existingEntry: DiaryEntry?

    @State private var content: String = ""
    @State private var selectedSticker: String = "🌸"
    @State private var photoDataArray: [Data] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showStickerPicker = false
    @State private var showDiscardAlert = false

    private var isEditing: Bool {
        existingEntry != nil
    }

    private var hasChanges: Bool {
        if let entry = existingEntry {
            return content != entry.content ||
                   selectedSticker != entry.stickerEmoji ||
                   photoDataArray != entry.photoDataArray
        }
        return !content.isEmpty || !photoDataArray.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.pastelBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        stickerSection
                        textSection
                        photoSection
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(isEditing ? "일기 수정" : "새 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pastelPinkLight.opacity(0.5), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.diaryTextLight)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                        dismiss()
                    } label: {
                        Text("저장")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(content.isEmpty ? Color.diaryTextMuted : Color.pastelPink)
                            )
                    }
                    .disabled(content.isEmpty)
                }
            }
            .alert("작성 중인 내용이 있어요", isPresented: $showDiscardAlert) {
                Button("계속 작성", role: .cancel) { }
                Button("나가기", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("저장하지 않고 나가면 작성 중인 내용이 사라져요.")
            }
            .onAppear {
                loadExistingEntry()
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task {
                    await loadPhotos(from: newPhotos)
                }
            }
        }
    }

    // MARK: - Sticker Section
    private var stickerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("오늘의 스티커")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.diaryText)
                Spacer()
            }

            Button {
                showStickerPicker.toggle()
            } label: {
                HStack(spacing: 12) {
                    Text(selectedSticker)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stickerName(for: selectedSticker))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.diaryText)
                        Text("탭하여 변경")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.diaryTextMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.diaryTextLight)
                        .rotationEffect(.degrees(showStickerPicker ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)

            if showStickerPicker {
                stickerGrid
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showStickerPicker)
    }

    private var stickerGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            ForEach(Sticker.all) { sticker in
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        selectedSticker = sticker.emoji
                        showStickerPicker = false
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(sticker.emoji)
                            .font(.system(size: 30))
                        Text(sticker.name)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.diaryTextLight)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSticker == sticker.emoji ?
                                  Color.pastelPinkLight : Color.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSticker == sticker.emoji ?
                                    Color.pastelPink : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Text Section
    private var textSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("오늘의 일기")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.diaryText)

                Spacer()

                Text("\(content.count)자")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.diaryTextMuted)
            }

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("오늘 하루는 어땠나요?\n자유롭게 적어보세요...")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.diaryTextMuted)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $content)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.diaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
            )
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("사진 첨부")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.diaryText)

                Spacer()

                Text("\(photoDataArray.count)/5")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.diaryTextMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add photo button
                    if photoDataArray.count < 5 {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 5 - photoDataArray.count,
                            matching: .images
                        ) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.pastelPink)
                                Text("추가")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.diaryTextLight)
                            }
                            .frame(width: 100, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.85))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                style: StrokeStyle(lineWidth: 2, dash: [6])
                                            )
                                            .foregroundColor(.pastelPink.opacity(0.5))
                                    )
                            )
                        }
                    }

                    // Existing photos
                    ForEach(photoDataArray.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            if let uiImage = UIImage(data: photoDataArray[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            Button {
                                withAnimation {
                                    photoDataArray.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
            )
        }
    }

    // MARK: - Helpers
    private func loadExistingEntry() {
        guard let entry = existingEntry else { return }
        content = entry.content
        selectedSticker = entry.stickerEmoji
        photoDataArray = entry.photoDataArray
    }

    private func save() {
        if let entry = existingEntry {
            entry.content = content
            entry.stickerEmoji = selectedSticker
            entry.photoDataArray = photoDataArray
            entry.updatedAt = Date()
        } else {
            let newEntry = DiaryEntry(
                dateKey: date.dateKey,
                content: content,
                photoDataArray: photoDataArray,
                stickerEmoji: selectedSticker
            )
            modelContext.insert(newEntry)
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Compress the image to reduce storage
                if let uiImage = UIImage(data: data),
                   let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                    await MainActor.run {
                        photoDataArray.append(compressed)
                    }
                }
            }
        }
        await MainActor.run {
            selectedPhotos = []
        }
    }

    private func stickerName(for emoji: String) -> String {
        Sticker.all.first(where: { $0.emoji == emoji })?.name ?? "스티커"
    }
}

#Preview {
    DiaryEditorView(date: Date(), existingEntry: nil)
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
