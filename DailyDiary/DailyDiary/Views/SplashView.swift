import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0
    @State private var offsetY: CGFloat = 30
    @State private var emojiScale = 0.5
    @State private var showMain = false

    var body: some View {
        if showMain {
            ContentView()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.pastelPink, Color.pastelLavender],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 배경 벚꽃 데코
                VStack {
                    HStack {
                        Image("flower").resizable().frame(width: 40, height: 40).opacity(0.4)
                        Spacer()
                        Image("flower").resizable().frame(width: 28, height: 28).opacity(0.3)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 80)

                    Spacer()

                    HStack {
                        Image("flower").resizable().frame(width: 24, height: 24).opacity(0.3)
                        Spacer()
                        Image("flower").resizable().frame(width: 36, height: 36).opacity(0.4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }

                // 메인 콘텐츠
                VStack(spacing: 20) {
                    Image("flower")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .scaleEffect(emojiScale)

                    VStack(spacing: 10) {
                        Text("My Daily Diary")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 232/255, green: 213/255, blue: 245/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("오늘을 기록해보세요")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.withOpacity(0.85))
                    }
                }
                .offset(y: offsetY)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    opacity = 1.0
                    offsetY = 0
                    emojiScale = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showMain = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .modelContainer(for: DiaryEntry.self, inMemory: true)
}
