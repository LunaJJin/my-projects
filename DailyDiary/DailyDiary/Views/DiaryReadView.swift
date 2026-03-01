import SwiftUI
import SwiftData
import UIKit
import Photos

struct DiaryReadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var showEditor = false
    @State private var showDeleteAlert = false
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveSuccessAlert = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // ── 1. 에디터와 동일한 도화지 배경 ──
                    Color(red: 254/255, green: 252/255, blue: 248/255)
                        .ignoresSafeArea()

                    // ── 2. 헤더 (상단 고정) ──
                    VStack(spacing: 0) {
                        HStack(alignment: .center) {
                            Text(entry.stickerEmoji)
                                .font(.system(size: 40))

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(dateString(from: entry.createdAt))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.diaryText)

                                HStack(spacing: 4) {
                                    Text(timeString(from: entry.createdAt))
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.diaryTextLight)

                                    if entry.updatedAt.timeIntervalSince(entry.createdAt) > 60 {
                                        Text("· 수정됨")
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(.diaryTextMuted)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                        Rectangle()
                            .fill(Color.pastelPinkLight.withOpacity(0.6))
                            .frame(height: 1)
                            .padding(.horizontal, 20)

                        Spacer()

                        // 구버전 일기 fallback: photos 없으면 하단 스트립 표시
                        if entry.canvasPhotos.isEmpty && !entry.photoDataArray.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(entry.photoDataArray.indices, id: \.self) { i in
                                        if let uiImage = UIImage(data: entry.photoDataArray[i]) {
                                            Button {
                                                selectedPhotoIndex = i
                                                showPhotoViewer = true
                                            } label: {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 90, height: 90)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 110)
                            .padding(.bottom, 8)
                        }
                    }

                    // ── 3. 텍스트 블록 (읽기전용) ──
                    if entry.textBlocks.isEmpty && !entry.content.isEmpty {
                        // 구버전 일기: content 중앙 표시
                        Text(entry.content)
                            .font(.system(size: 17, design: .rounded))
                            .foregroundColor(.diaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .frame(maxWidth: geo.size.width * 0.78)
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.45)
                            .allowsHitTesting(false)
                    } else {
                        ForEach(entry.textBlocks) { block in
                            staticTextBlock(block)
                                .zIndex(Double(block.zOrder))
                        }
                    }

                    // ── 4. 사진 레이어 (읽기전용) ──
                    ForEach(entry.canvasPhotos.indices, id: \.self) { i in
                        let photo = entry.canvasPhotos[i]
                        if let uiImage = UIImage(data: photo.data) {
                            let fs = photoFrameSize(uiImage, maxDim: 200)
                            Button {
                                selectedPhotoIndex = i
                                showPhotoViewer = true
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: fs.width, height: fs.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .scaleEffect(photo.scale)
                                    .rotationEffect(.degrees(photo.rotation))
                                    .position(x: photo.x, y: photo.y)
                            }
                            .buttonStyle(.plain)
                            .zIndex(Double(photo.zOrder))
                        }
                    }

                    // ── 5. 스티커 (읽기전용) ──
                    ForEach(entry.stickers) { sticker in
                        Image(sticker.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .scaleEffect(sticker.scale)
                            .rotationEffect(.degrees(sticker.rotation))
                            .position(x: sticker.x, y: sticker.y)
                            .allowsHitTesting(false)
                            .zIndex(Double(sticker.zOrder))
                    }
                }
                .onAppear {
                    canvasSize = geo.size
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pastelPinkLight.withOpacity(0.5), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pastelPink)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { saveImageToPhotos() } label: {
                            Label("이미지 저장", systemImage: "square.and.arrow.down")
                        }
                        Button { showEditor = true } label: {
                            Label("수정", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
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
            }
            .sheet(isPresented: $showEditor) {
                DiaryEditorView(date: entry.createdAt, existingEntry: entry)
                    .presentationDetents([.large])
                    .presentationCornerRadius(32)
            }
            .fullScreenCover(isPresented: $showPhotoViewer) {
                let photoDataList = entry.canvasPhotos.isEmpty
                    ? entry.photoDataArray
                    : entry.canvasPhotos.map { $0.data }
                PhotoViewerView(photos: photoDataList, currentIndex: selectedPhotoIndex)
            }
            .alert("저장 완료", isPresented: $showSaveSuccessAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("일기가 사진 앨범에 저장되었어요.")
            }
            .alert("일기 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    withAnimation {
                        modelContext.delete(entry)
                        dismiss()
                    }
                }
            } message: {
                Text("이 일기를 정말 삭제할까요?\n삭제하면 되돌릴 수 없어요.")
            }
        }
    }

    // MARK: - 이미지 저장
    @MainActor
    private func saveImageToPhotos() {
        let size = canvasSize.width > 0 ? canvasSize : UIScreen.main.bounds.size
        let view = DiaryExportView(entry: entry, size: size)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                if success {
                    DispatchQueue.main.async {
                        showSaveSuccessAlert = true
                    }
                }
            }
        }
    }

    // MARK: - 텍스트 블록 (읽기전용)
    private func staticTextBlock(_ block: DiaryTextBlock) -> some View {
        Text(block.text)
            .font(DiaryFont.font(name: block.fontName, size: block.fontSize, isBold: block.isBold))
            .foregroundColor(DiaryColor.color(name: block.colorName))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
            .shadow(color: DiaryColor.needsShadow(name: block.colorName) ? Color.black.opacity(0.4) : .clear, radius: 3)
            .scaleEffect(block.scale)
            .rotationEffect(.degrees(block.rotation))
            .position(x: block.x, y: block.y)
            .allowsHitTesting(false)
    }

    // MARK: - Helpers
    private func photoFrameSize(_ uiImage: UIImage, maxDim: CGFloat = 200) -> CGSize {
        let w = uiImage.size.width
        let h = Swift.max(uiImage.size.height, 1)
        let aspect = w / h
        return aspect >= 1
            ? CGSize(width: maxDim, height: maxDim / aspect)
            : CGSize(width: maxDim * aspect, height: maxDim)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 공유용 캔버스 스냅샷 뷰
private struct DiaryExportView: View {
    let entry: DiaryEntry
    let size: CGSize

    var body: some View {
        ZStack {
            // 1. 크림 배경
            Color(red: 254/255, green: 252/255, blue: 248/255)

            // 2. 헤더
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text(entry.stickerEmoji)
                        .font(.system(size: 40))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(dateString(from: entry.createdAt))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.diaryText)

                        HStack(spacing: 4) {
                            Text(timeString(from: entry.createdAt))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.diaryTextLight)

                            if entry.updatedAt.timeIntervalSince(entry.createdAt) > 60 {
                                Text("· 수정됨")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.diaryTextMuted)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Rectangle()
                    .fill(Color.pastelPinkLight.withOpacity(0.6))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                Spacer()
            }

            // 3. 텍스트 블록
            if entry.textBlocks.isEmpty && !entry.content.isEmpty {
                Text(entry.content)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(.diaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .frame(maxWidth: size.width * 0.78)
                    .position(x: size.width / 2, y: size.height * 0.45)
            } else {
                ForEach(entry.textBlocks) { block in
                    exportTextBlock(block)
                }
            }

            // 4. 사진 레이어
            ForEach(entry.canvasPhotos.indices, id: \.self) { i in
                let photo = entry.canvasPhotos[i]
                if let uiImage = UIImage(data: photo.data) {
                    let fs = exportPhotoFrame(uiImage, maxDim: 200)
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: fs.width, height: fs.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scaleEffect(photo.scale)
                        .rotationEffect(.degrees(photo.rotation))
                        .position(x: photo.x, y: photo.y)
                        .zIndex(Double(photo.zOrder))
                }
            }

            // 5. 스티커
            ForEach(entry.stickers) { sticker in
                Image(sticker.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .scaleEffect(sticker.scale)
                    .rotationEffect(.degrees(sticker.rotation))
                    .position(x: sticker.x, y: sticker.y)
                    .zIndex(Double(sticker.zOrder))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func exportPhotoFrame(_ uiImage: UIImage, maxDim: CGFloat = 200) -> CGSize {
        let w = uiImage.size.width
        let h = Swift.max(uiImage.size.height, 1)
        let aspect = w / h
        return aspect >= 1
            ? CGSize(width: maxDim, height: maxDim / aspect)
            : CGSize(width: maxDim * aspect, height: maxDim)
    }

    private func exportTextBlock(_ block: DiaryTextBlock) -> some View {
        Text(block.text)
            .font(DiaryFont.font(name: block.fontName, size: block.fontSize, isBold: block.isBold))
            .foregroundColor(DiaryColor.color(name: block.colorName))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
            .shadow(color: DiaryColor.needsShadow(name: block.colorName) ? Color.black.opacity(0.4) : .clear, radius: 3)
            .scaleEffect(block.scale)
            .rotationEffect(.degrees(block.rotation))
            .position(x: block.x, y: block.y)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}
