import SwiftUI

private let allStickerNames: [String] =
    (1...16).map { String(format: "sticker1_%02d", $0) } +
    (1...9).map  { String(format: "sticker3_%02d", $0) }

// MARK: - DiaryDecorateView
struct DiaryDecorateView: View {
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry
    /// 뷰어/에디터에서 호출 시 완료 후 실행할 추가 동작
    var onComplete: (() -> Void)? = nil

    @State private var stickers: [DiarySticker] = []
    @State private var showPicker = false
    @State private var selectedStickerID: UUID? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // 배경 (항상 꽉 채움)
                    LinearGradient.pastelBackground
                        .ignoresSafeArea()

                    // 일기 내용 (읽기전용)
                    diaryBackground
                        .frame(width: geo.size.width, height: geo.size.height)

                    // 사진 레이어 (읽기전용)
                    ForEach(entry.photos) { photo in
                        if let uiImage = UIImage(data: photo.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .scaleEffect(photo.scale)
                                .rotationEffect(.degrees(photo.rotation))
                                .position(x: photo.x, y: photo.y)
                                .allowsHitTesting(false)
                        }
                    }

                    // 텍스트 블록 레이어 (읽기전용)
                    ForEach(entry.textBlocks) { block in
                        staticTextBlock(block)
                    }

                    // 스티커 레이어
                    ForEach($stickers) { $sticker in
                        StickerImageView(
                            sticker: $sticker,
                            isSelected: selectedStickerID == sticker.id,
                            canvasSize: geo.size,
                            onTap: { selectedStickerID = sticker.id },
                            onDelete: { removeSticker(id: sticker.id) }
                        )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedStickerID = nil }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("스티커 다꾸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pastelPinkLight.withOpacity(0.5), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.diaryTextLight)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { save() } label: {
                        Text("완료")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.pastelPink))
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button { showPicker = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                            Text("스티커 추가")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.pastelPink)
                    }
                }
            }
            .onAppear { stickers = entry.stickers }
            .sheet(isPresented: $showPicker) {
                StickerPickerSheet { name in
                    addSticker(imageName: name)
                    showPicker = false
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
            }
        }
    }

    // MARK: - 텍스트 블록 (읽기전용)
    private func staticTextBlock(_ block: DiaryTextBlock) -> some View {
        let color: Color = {
            switch block.colorName {
            case "white": return .white
            case "pink": return .pastelPink
            default: return .diaryText
            }
        }()
        return Text(block.text)
            .font(.system(size: block.fontSize, weight: block.isBold ? .bold : .regular, design: .rounded))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 260)
            .shadow(color: block.colorName == "white" ? Color.black.opacity(0.4) : .clear, radius: 3)
            .scaleEffect(block.scale)
            .rotationEffect(.degrees(block.rotation))
            .position(x: block.x, y: block.y)
            .allowsHitTesting(false)
    }

    // MARK: - 읽기전용 일기 배경
    private var diaryBackground: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(entry.stickerEmoji)
                    .font(.system(size: 28))
                if !entry.content.isEmpty && entry.textBlocks.isEmpty {
                    // 텍스트 블록 없는 구버전 일기만 미리보기 표시
                    Text("\(entry.content.prefix(50))\(entry.content.count > 50 ? "..." : "")")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.diaryTextMuted)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // 구버전 일기 fallback: photos 없으면 photoDataArray 스트립 표시
            if entry.photos.isEmpty && !entry.photoDataArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.photoDataArray.indices, id: \.self) { i in
                            if let uiImage = UIImage(data: entry.photoDataArray[i]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers
    private func addSticker(imageName: String) {
        let s = DiarySticker(imageName: imageName, x: 200, y: 350)
        stickers.append(s)
        selectedStickerID = s.id
    }

    private func removeSticker(id: UUID) {
        stickers.removeAll { $0.id == id }
        if selectedStickerID == id { selectedStickerID = nil }
    }

    private func save() {
        entry.stickers = stickers
        onComplete?()
        dismiss()
    }
}

// MARK: - StickerImageView
struct StickerImageView: View {
    @Binding var sticker: DiarySticker
    let isSelected: Bool
    let canvasSize: CGSize
    let onTap: () -> Void
    let onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var showDeleteButton = false

    private let baseSize: CGFloat = 90

    var body: some View {
        ZStack {
            Image(sticker.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: baseSize, height: baseSize)
                .scaleEffect(sticker.scale * gestureScale)
                .rotationEffect(.degrees(sticker.rotation) + gestureRotation)
                .offset(dragOffset)
                .position(x: sticker.x, y: sticker.y)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.pastelPink.withOpacity(0.8), lineWidth: 1.5)
                            .frame(
                                width: baseSize * sticker.scale * gestureScale + 10,
                                height: baseSize * sticker.scale * gestureScale + 10
                            )
                            .rotationEffect(.degrees(sticker.rotation) + gestureRotation)
                            .offset(dragOffset)
                            .position(x: sticker.x, y: sticker.y)
                    }
                }
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .updating($dragOffset) { v, s, _ in s = v.translation }
                            .onEnded { v in
                                sticker.x = min(max(sticker.x + v.translation.width, 0), canvasSize.width)
                                sticker.y = min(max(sticker.y + v.translation.height, 0), canvasSize.height)
                            },
                        SimultaneousGesture(
                            MagnificationGesture()
                                .updating($gestureScale) { v, s, _ in s = v }
                                .onEnded { v in sticker.scale = max(0.3, min(sticker.scale * v, 5.0)) },
                            RotationGesture()
                                .updating($gestureRotation) { v, s, _ in s = v }
                                .onEnded { v in sticker.rotation += v.degrees }
                        )
                    )
                )
                .onTapGesture { onTap() }
                .onLongPressGesture {
                    onTap()
                    showDeleteButton = true
                }

            if isSelected && showDeleteButton {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                }
                .position(
                    x: sticker.x + baseSize * sticker.scale / 2 + 4,
                    y: sticker.y - baseSize * sticker.scale / 2 - 4
                )
            }
        }
        .onChange(of: isSelected) { _, newVal in
            if !newVal { showDeleteButton = false }
        }
    }
}

// MARK: - TextBlockView
struct TextBlockView: View {
    @Binding var block: DiaryTextBlock
    let isSelected: Bool
    let canvasSize: CGSize
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var showDeleteButton = false

    private var textColor: Color {
        switch block.colorName {
        case "white": return .white
        case "pink": return .pastelPink
        default: return .diaryText
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(block.text)
                .font(.system(size: block.fontSize, weight: block.isBold ? .bold : .regular, design: .rounded))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 260)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .shadow(color: block.colorName == "white" ? Color.black.opacity(0.4) : .clear, radius: 3)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.pastelPink.withOpacity(0.8), lineWidth: 1.5)
                    }
                }

            if isSelected && showDeleteButton {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                }
                .offset(x: 11, y: -11)
            }
        }
        .scaleEffect(block.scale * gestureScale)
        .rotationEffect(.degrees(block.rotation) + gestureRotation)
        .offset(dragOffset)
        .position(x: block.x, y: block.y)
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .updating($dragOffset) { v, s, _ in s = v.translation }
                    .onEnded { v in
                        block.x = min(max(block.x + v.translation.width, 0), canvasSize.width)
                        block.y = min(max(block.y + v.translation.height, 0), canvasSize.height)
                    },
                SimultaneousGesture(
                    MagnificationGesture()
                        .updating($gestureScale) { v, s, _ in s = v }
                        .onEnded { v in block.scale = max(0.3, min(block.scale * v, 5.0)) },
                    RotationGesture()
                        .updating($gestureRotation) { v, s, _ in s = v }
                        .onEnded { v in block.rotation += v.degrees }
                )
            )
        )
        .onTapGesture {
            if isSelected { onEdit() } else { onTap() }
        }
        .onLongPressGesture {
            onTap()
            showDeleteButton = true
        }
        .onChange(of: isSelected) { _, newVal in
            if !newVal { showDeleteButton = false }
        }
    }
}

// MARK: - PhotoCanvasView
struct PhotoCanvasView: View {
    @Binding var photo: DiaryPhoto
    let isSelected: Bool
    let canvasSize: CGSize
    let onTap: () -> Void
    let onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var showDeleteButton = false

    private let baseSize: CGFloat = 150

    var body: some View {
        ZStack {
            if let uiImage = UIImage(data: photo.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: baseSize, height: baseSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scaleEffect(photo.scale * gestureScale)
                    .rotationEffect(.degrees(photo.rotation) + gestureRotation)
                    .offset(dragOffset)
                    .position(x: photo.x, y: photo.y)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.pastelPink.withOpacity(0.8), lineWidth: 1.5)
                                .frame(
                                    width: baseSize * photo.scale * gestureScale + 10,
                                    height: baseSize * photo.scale * gestureScale + 10
                                )
                                .rotationEffect(.degrees(photo.rotation) + gestureRotation)
                                .offset(dragOffset)
                                .position(x: photo.x, y: photo.y)
                        }
                    }
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .updating($dragOffset) { v, s, _ in s = v.translation }
                                .onEnded { v in
                                    photo.x = min(max(photo.x + v.translation.width, 0), canvasSize.width)
                                    photo.y = min(max(photo.y + v.translation.height, 0), canvasSize.height)
                                },
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .updating($gestureScale) { v, s, _ in s = v }
                                    .onEnded { v in photo.scale = max(0.2, min(photo.scale * v, 5.0)) },
                                RotationGesture()
                                    .updating($gestureRotation) { v, s, _ in s = v }
                                    .onEnded { v in photo.rotation += v.degrees }
                            )
                        )
                    )
                    .onTapGesture { onTap() }
                    .onLongPressGesture { onTap(); showDeleteButton = true }
            }

            if isSelected && showDeleteButton {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                }
                .position(
                    x: photo.x + baseSize * photo.scale / 2 + 4,
                    y: photo.y - baseSize * photo.scale / 2 - 4
                )
            }
        }
        .onChange(of: isSelected) { _, newVal in
            if !newVal { showDeleteButton = false }
        }
    }
}

// MARK: - StickerPickerSheet
struct StickerPickerSheet: View {
    let onSelect: (String) -> Void
    private let columns = [GridItem(.adaptive(minimum: 75), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            Text("스티커 선택")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.diaryText)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(allStickerNames, id: \.self) { name in
                        Button { onSelect(name) } label: {
                            Image(name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.pastelPinkLight.withOpacity(0.4))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .background(LinearGradient.pastelBackground.ignoresSafeArea())
    }
}
