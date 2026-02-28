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
    @State private var showEmojiPicker = false
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
            .toolbarBackground(Color.pastelPinkLight.withOpacity(0.5), for: .navigationBar)
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
                Text("오늘의 이모지")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.diaryText)
                Spacer()
            }

            Button {
                showEmojiPicker = true
            } label: {
                HStack(spacing: 12) {
                    Text(selectedSticker)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("탭하여 변경")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.diaryText)
                        Text("이모지 키보드에서 자유롭게 선택")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.diaryTextMuted)
                    }

                    Spacer()

                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(.pastelPink)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.withOpacity(0.85))
                        .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(selectedEmoji: $selectedSticker)
                .presentationDetents([.height(300)])
                .presentationCornerRadius(28)
        }
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
                    .fill(Color.white.withOpacity(0.85))
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
                    if photoDataArray.count < 5 {
                        addPhotoButton
                    }
                    ForEach(photoDataArray.indices, id: \.self) { index in
                        photoCard(at: index)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.withOpacity(0.85))
                    .shadow(color: .cardShadow, radius: 8, x: 0, y: 4)
            )
        }
    }

    private var addPhotoButton: some View {
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
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.withOpacity(0.85))
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            Color.pastelPink.withOpacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [6])
                        )
                }
            )
        }
    }

    private func photoCard(at index: Int) -> some View {
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
                    var updated = photoDataArray
                    updated.remove(at: index)
                    photoDataArray = updated
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

}

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("이모지 선택")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)
                .padding(.top, 24)

            Text(selectedEmoji)
                .font(.system(size: 80))

            Text("키보드의 🌐 버튼을 눌러 이모지를 선택하세요")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.diaryTextLight)
                .multilineTextAlignment(.center)

            EmojiTextField(selectedEmoji: $selectedEmoji) {
                dismiss()
            }
            .frame(width: 80, height: 50)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    DiaryEditorView(date: Date(), existingEntry: nil)
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
