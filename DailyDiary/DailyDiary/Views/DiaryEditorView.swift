import SwiftUI
import SwiftData
import PhotosUI

struct DiaryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let existingEntry: DiaryEntry?

    // Canvas elements
    @State private var selectedSticker: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoItems: [DiaryPhoto] = []
    @State private var stickers: [DiarySticker] = []
    @State private var textBlocks: [DiaryTextBlock] = []
    @State private var selectedPhotoID: UUID? = nil
    @State private var selectedStickerID: UUID? = nil
    @State private var selectedTextBlockID: UUID? = nil

    // 인라인 텍스트 편집
    @State private var showTextInput = false
    @State private var editingTextBlockID: UUID? = nil
    @State private var inputText: String = ""
    @State private var inputColorName: String = "primary"
    @State private var inputIsBold: Bool = false
    @State private var inputFontSize: CGFloat = 20
    @FocusState private var isTextFocused: Bool

    // UI state
    @State private var showEmojiPicker = false
    @State private var showStickerPicker = false
    @State private var showDiscardAlert = false
    @State private var showSaveEffect = false
    @State private var canvasSize: CGSize = .zero
    @State private var showDeleteZone = false
    @State private var overDeleteZone = false

    private var isEditing: Bool { existingEntry != nil }

    private var hasChanges: Bool {
        if let entry = existingEntry {
            return selectedSticker != entry.stickerEmoji
                || photoItems.count != entry.canvasPhotos.count
                || stickers.count != entry.stickers.count
                || textBlocks.count != entry.textBlocks.count
        }
        return !textBlocks.isEmpty || !photoItems.isEmpty || !stickers.isEmpty
    }

    private var inputTextColor: Color {
        switch inputColorName {
        case "white": return .white
        case "pink": return .pastelPink
        default: return .diaryText
        }
    }

    var body: some View {
        NavigationStack { editorCanvas }
    }

    private var editorCanvas: some View {
        GeometryReader { geo in
            canvasLayers(geo: geo)
                .onAppear {
                    if geo.size.width > 0 { canvasSize = geo.size }
                }
        }
        .navigationTitle(isEditing ? "일기 수정" : "새 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pastelPinkLight.withOpacity(0.5), for: .navigationBar)
            .toolbarBackground(
                showTextInput ? Color.white.opacity(0.92) : Color.clear,
                for: .bottomBar
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        if showTextInput {
                            withAnimation(.easeInOut(duration: 0.2)) { showTextInput = false }
                        } else {
                            if hasChanges { showDiscardAlert = true } else { dismiss() }
                        }
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.diaryTextLight)
                }

                if showTextInput {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") { confirmTextInput() }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.pastelPink)
                    }
                }

                if showTextInput {
                    ToolbarItemGroup(placement: .bottomBar) {
                        colorDotButton("primary", Color.diaryText)
                        colorDotButton("white", Color.white)
                        colorDotButton("pink", Color.pastelPink)
                        Spacer()
                        Button { inputIsBold.toggle() } label: {
                            Image(systemName: "bold")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(inputIsBold ? Color.pastelPink : .diaryTextMuted)
                        }
                        Spacer()
                        Button { inputFontSize = max(13, inputFontSize - 2) } label: {
                            Image(systemName: "textformat.size.smaller").foregroundColor(.diaryText)
                        }
                        Text("\(Int(inputFontSize))")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.diaryText)
                            .frame(width: 28)
                        Button { inputFontSize = min(34, inputFontSize + 2) } label: {
                            Image(systemName: "textformat.size.larger").foregroundColor(.diaryText)
                        }
                    }
                } else {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            selectedPhotoID = nil; selectedStickerID = nil; selectedTextBlockID = nil
                            openTextInput()
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "textformat").font(.system(size: 20))
                                Text("텍스트").font(.system(size: 10, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.pastelPink)
                        }
                        Spacer()
                        Button {
                            selectedPhotoID = nil; selectedStickerID = nil; selectedTextBlockID = nil
                            showStickerPicker = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "wand.and.stars").font(.system(size: 20))
                                Text("스티커").font(.system(size: 10, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.pastelPink)
                        }
                        Spacer()
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: max(1, 10 - photoItems.count),
                            matching: .images
                        ) {
                            VStack(spacing: 2) {
                                Image(systemName: "photo").font(.system(size: 20))
                                Text("사진").font(.system(size: 10, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(photoItems.count >= 10 ? .diaryTextMuted : .pastelPink)
                        }
                        .disabled(photoItems.count >= 10)
                        Spacer()
                        Button {
                            save()
                            showSaveEffect = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                                Text("완료").font(.system(size: 10, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.pastelPink)
                        }
                    }
                }
            }
            .alert("작성 중인 내용이 있어요", isPresented: $showDiscardAlert) {
                Button("계속 작성", role: .cancel) { }
                Button("나가기", role: .destructive) { dismiss() }
            } message: {
                Text("저장하지 않고 나가면 작성 중인 내용이 사라져요.")
            }
            .onAppear { loadExistingEntry() }
            .onChange(of: showTextInput) { _, newVal in
                if newVal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isTextFocused = true
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task { await loadPhotos(from: newPhotos) }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selectedEmoji: $selectedSticker)
                    .presentationDetents([.height(300)])
                    .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showStickerPicker) {
                StickerPickerSheet { name in
                    addSticker(imageName: name)
                    showStickerPicker = false
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
            }
    }

    // MARK: - Canvas Layers
    @ViewBuilder
    private func canvasLayers(geo: GeometryProxy) -> some View {
        ZStack {
            // ── 1. 도화지 배경 ──
            Color(red: 254/255, green: 252/255, blue: 248/255)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedPhotoID = nil
                    selectedStickerID = nil
                    selectedTextBlockID = nil
                }

            // ── 2. 빈 캔버스 힌트 ──
            if textBlocks.isEmpty && stickers.isEmpty && photoItems.isEmpty && !showTextInput {
                VStack {
                    Spacer().frame(height: 130)
                    Text("텍스트나 스티커를 추가해보세요")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.diaryTextMuted)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // ── 3. 텍스트 블록 레이어 ──
            ForEach($textBlocks) { $block in
                TextBlockView(
                    block: $block,
                    isSelected: selectedTextBlockID == block.id,
                    canvasSize: geo.size,
                    showDeleteZone: $showDeleteZone,
                    overDeleteZone: $overDeleteZone,
                    onTap: { selectedTextBlockID = block.id; selectedStickerID = nil; selectedPhotoID = nil },
                    onEdit: { startEditing(block) },
                    onDelete: { removeTextBlock(id: block.id) }
                )
            }

            // ── 4. 사진 레이어 ──
            ForEach($photoItems) { $photo in
                PhotoCanvasView(
                    photo: $photo,
                    isSelected: selectedPhotoID == photo.id,
                    canvasSize: geo.size,
                    showDeleteZone: $showDeleteZone,
                    overDeleteZone: $overDeleteZone,
                    onTap: { selectedPhotoID = photo.id; selectedStickerID = nil; selectedTextBlockID = nil },
                    onDelete: { removePhoto(id: photo.id) }
                )
            }

            // ── 5. 스티커 레이어 ──
            ForEach($stickers) { $sticker in
                StickerImageView(
                    sticker: $sticker,
                    isSelected: selectedStickerID == sticker.id,
                    canvasSize: geo.size,
                    showDeleteZone: $showDeleteZone,
                    overDeleteZone: $overDeleteZone,
                    onTap: { selectedStickerID = sticker.id; selectedTextBlockID = nil; selectedPhotoID = nil },
                    onDelete: { removeSticker(id: sticker.id) }
                )
            }

            // ── 6. 헤더 (상단 고정) ──
            headerStrip

            // ── 7. 인라인 텍스트 편집 오버레이 ──
            if showTextInput {
                textInputOverlay(geo: geo)
            }

            // ── 8. 삭제 존 (드래그 중) ──
            if showDeleteZone && !showTextInput {
                DeleteZoneView(over: overDeleteZone)
                    .allowsHitTesting(false)
                    .position(x: geo.size.width / 2, y: geo.size.height - 100)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }

            // ── 9. 저장 효과 ──
            if showSaveEffect {
                CherryBlossomEffect().allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var headerStrip: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button { showEmojiPicker = true } label: {
                    if selectedSticker.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pastelPink.withOpacity(0.08))
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color.pastelPink.withOpacity(0.55),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                                )
                            VStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("이모지")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.pastelPink.withOpacity(0.8))
                        }
                        .frame(width: 50, height: 50)
                    } else {
                        Text(selectedSticker)
                            .font(.system(size: 40))
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.pastelPink)
                                    .offset(x: 6, y: 6)
                            }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Spacer()

                Text(date.koreanFullDateString)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.diaryTextLight)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Rectangle()
                .fill(Color.pastelPinkLight.withOpacity(0.6))
                .frame(height: 1)
                .padding(.horizontal, 20)

            Spacer()
        }
        .allowsHitTesting(!showTextInput)
    }

    @ViewBuilder
    private func textInputOverlay(geo: GeometryProxy) -> some View {
        // 캔버스 중앙에 텍스트 입력 박스 — 어두운 오버레이 없이 화면에 바로 쓰는 느낌
        ZStack {
            if inputText.isEmpty {
                Text("텍스트를 입력하세요")
                    .font(.system(size: inputFontSize,
                                  weight: inputIsBold ? .bold : .regular,
                                  design: .rounded))
                    .foregroundColor(inputTextColor.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $inputText)
                .font(.system(size: inputFontSize,
                              weight: inputIsBold ? .bold : .regular,
                              design: .rounded))
                .foregroundColor(inputTextColor)
                .multilineTextAlignment(.center)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isTextFocused)
        }
        .frame(width: geo.size.width * 0.85, height: 200)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.85))
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.pastelPink.withOpacity(0.45), lineWidth: 1.5)
            }
        )
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        .position(x: geo.size.width / 2, y: geo.size.height * 0.38)
    }

    // MARK: - colorDotButton
    @ViewBuilder
    private func colorDotButton(_ name: String, _ color: Color) -> some View {
        Button { inputColorName = name } label: {
            ZStack {
                Circle().fill(color).frame(width: 26, height: 26)
                if inputColorName == name {
                    Circle().strokeBorder(Color.white, lineWidth: 2).frame(width: 32, height: 32)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Block Helpers
    private func openTextInput() {
        editingTextBlockID = nil
        inputText = ""
        inputColorName = "primary"
        inputIsBold = false
        inputFontSize = 20
        withAnimation(.easeInOut(duration: 0.2)) { showTextInput = true }
    }

    private func startEditing(_ block: DiaryTextBlock) {
        editingTextBlockID = block.id
        inputText = block.text
        inputColorName = block.colorName
        inputIsBold = block.isBold
        inputFontSize = block.fontSize
        withAnimation(.easeInOut(duration: 0.2)) { showTextInput = true }
    }

    private func confirmTextInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if let editID = editingTextBlockID {
                removeTextBlock(id: editID)
            }
        } else if let editID = editingTextBlockID,
                  let idx = textBlocks.firstIndex(where: { $0.id == editID }) {
            textBlocks[idx].text = trimmed
            textBlocks[idx].colorName = inputColorName
            textBlocks[idx].isBold = inputIsBold
            textBlocks[idx].fontSize = inputFontSize
        } else {
            let cx = canvasSize.width  > 0 ? canvasSize.width  / 2 : 195
            let cy = canvasSize.height > 0 ? canvasSize.height * 0.42 : 360
            let block = DiaryTextBlock(
                text: trimmed, x: cx, y: cy,
                fontSize: inputFontSize, colorName: inputColorName, isBold: inputIsBold
            )
            textBlocks.append(block)
            selectedTextBlockID = block.id
        }

        withAnimation(.easeInOut(duration: 0.2)) { showTextInput = false }
    }

    private func removeTextBlock(id: UUID) {
        textBlocks.removeAll { $0.id == id }
        if selectedTextBlockID == id { selectedTextBlockID = nil }
    }

    // MARK: - Sticker Helpers
    private func addSticker(imageName: String) {
        let cx = canvasSize.width  > 0 ? canvasSize.width  / 2 : 195
        let cy = canvasSize.height > 0 ? canvasSize.height * 0.45 : 390
        let s = DiarySticker(imageName: imageName, x: cx, y: cy)
        stickers.append(s)
        selectedStickerID = s.id
    }

    private func removeSticker(id: UUID) {
        stickers.removeAll { $0.id == id }
        if selectedStickerID == id { selectedStickerID = nil }
    }

    // MARK: - Photo Helpers
    private func removePhoto(id: UUID) {
        photoItems.removeAll { $0.id == id }
        if selectedPhotoID == id { selectedPhotoID = nil }
    }

    // MARK: - Persistence
    private func loadExistingEntry() {
        guard let entry = existingEntry else { return }
        selectedSticker = entry.stickerEmoji
        stickers = entry.stickers

        // 사진: 새 형식 우선, 없으면 구버전 photoDataArray 마이그레이션
        let loadedPhotos = entry.canvasPhotos
        if loadedPhotos.isEmpty && !entry.photoDataArray.isEmpty {
            let cx: CGFloat = canvasSize.width  > 0 ? canvasSize.width  / 2 : 195
            let cy: CGFloat = canvasSize.height > 0 ? canvasSize.height * 0.50 : 430
            let count = entry.photoDataArray.count
            let spacing: CGFloat = 170
            let totalWidth = CGFloat(count - 1) * spacing
            let startX = cx - totalWidth / 2
            photoItems = entry.photoDataArray.enumerated().map { i, data in
                DiaryPhoto(data: data, x: startX + CGFloat(i) * spacing, y: cy)
            }
        } else {
            photoItems = loadedPhotos
        }

        // 텍스트: 새 형식 우선, 없으면 구버전 content 마이그레이션
        let loaded = entry.textBlocks
        if loaded.isEmpty && !entry.content.isEmpty {
            let cx: CGFloat = canvasSize.width > 0 ? canvasSize.width / 2 : 195
            textBlocks = [DiaryTextBlock(text: entry.content, x: cx, y: 280, fontSize: 17)]
        } else {
            textBlocks = loaded
        }
    }

    private func save() {
        let emoji = selectedSticker.isEmpty ? "🌸" : selectedSticker
        let derivedContent = textBlocks.map { $0.text }.filter { !$0.isEmpty }.joined(separator: "\n\n")
        if let entry = existingEntry {
            entry.content = derivedContent
            entry.stickerEmoji = emoji
            entry.photoDataArray = photoItems.map { $0.data }
            entry.stickers = stickers
            entry.textBlocks = textBlocks
            entry.canvasPhotos = photoItems
            entry.updatedAt = Date()
        } else {
            let newEntry = DiaryEntry(
                dateKey: date.dateKey,
                content: derivedContent,
                photoDataArray: photoItems.map { $0.data },
                stickerEmoji: emoji
            )
            newEntry.stickers = stickers
            newEntry.textBlocks = textBlocks
            newEntry.canvasPhotos = photoItems
            modelContext.insert(newEntry)
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        let cx = canvasSize.width  > 0 ? canvasSize.width  / 2 : 195
        let cy = canvasSize.height > 0 ? canvasSize.height * 0.45 : 390
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                await MainActor.run {
                    let photo = DiaryPhoto(data: compressed, x: cx, y: cy)
                    photoItems.append(photo)
                    selectedPhotoID = photo.id
                }
            }
        }
        await MainActor.run { selectedPhotos = [] }
    }
}

// MARK: - EmojiPickerSheet
struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("이모지 선택")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)
                .padding(.top, 24)

            if selectedEmoji.isEmpty {
                Image("flower")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .opacity(0.6)
            } else {
                Text(selectedEmoji).font(.system(size: 80))
            }

            Text("키보드의 🌐 버튼을 눌러 이모지를 선택하세요")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.diaryTextLight)
                .multilineTextAlignment(.center)

            EmojiTextField(selectedEmoji: $selectedEmoji) { dismiss() }
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
