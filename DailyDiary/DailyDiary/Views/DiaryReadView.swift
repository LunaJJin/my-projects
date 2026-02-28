import SwiftUI
import SwiftData

struct DiaryReadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var showEditor = false
    @State private var showDeleteAlert = false
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0

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
                        if entry.photos.isEmpty && !entry.photoDataArray.isEmpty {
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
                        }
                    }

                    // ── 4. 사진 레이어 (읽기전용) ──
                    ForEach(entry.photos.indices, id: \.self) { i in
                        let photo = entry.photos[i]
                        if let uiImage = UIImage(data: photo.data) {
                            Button {
                                selectedPhotoIndex = i
                                showPhotoViewer = true
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .scaleEffect(photo.scale)
                                    .rotationEffect(.degrees(photo.rotation))
                                    .position(x: photo.x, y: photo.y)
                            }
                            .buttonStyle(.plain)
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
                    }
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
                let photoDataList = entry.photos.isEmpty
                    ? entry.photoDataArray
                    : entry.photos.map { $0.data }
                PhotoViewerView(photos: photoDataList, currentIndex: selectedPhotoIndex)
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

    // MARK: - 텍스트 블록 (읽기전용)
    private func staticTextBlock(_ block: DiaryTextBlock) -> some View {
        let color: Color = {
            switch block.colorName {
            case "white": return .white
            case "pink":  return .pastelPink
            default:      return .diaryText
            }
        }()
        return Text(block.text)
            .font(.system(size: block.fontSize, weight: block.isBold ? .bold : .regular, design: .rounded))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
            .shadow(color: block.colorName == "white" ? Color.black.opacity(0.4) : .clear, radius: 3)
            .scaleEffect(block.scale)
            .rotationEffect(.degrees(block.rotation))
            .position(x: block.x, y: block.y)
            .allowsHitTesting(false)
    }

    // MARK: - Helpers
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