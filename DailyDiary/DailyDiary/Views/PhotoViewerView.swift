import SwiftUI

struct PhotoViewerView: View {
    let photos: [Data]
    @State var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    if let uiImage = UIImage(data: photos[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding(16)
        }
    }
}
