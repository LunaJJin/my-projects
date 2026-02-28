import SwiftUI

struct CherryBlossomEffect: View {
    struct Particle: Identifiable {
        let id = UUID()
        let startX: CGFloat   // 화면 너비 비율 (0~1)
        let size: CGFloat
        let rotation: Double
        let delay: Double
        let duration: Double
        let drift: CGFloat    // 좌우 흔들림
    }

    @State private var animate = false

    private let particles: [Particle] = (0..<28).map { _ in
        Particle(
            startX: CGFloat.random(in: 0.05...0.95),
            size: CGFloat.random(in: 22...44),
            rotation: Double.random(in: 270...630),
            delay: Double.random(in: 0...0.7),
            duration: Double.random(in: 0.9...1.4),
            drift: CGFloat.random(in: -60...60)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Image("flower")
                    .resizable()
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: geo.size.width * p.startX + (animate ? p.drift : 0),
                        y: animate ? geo.size.height + 50 : -50
                    )
                    .rotationEffect(.degrees(animate ? p.rotation : 0))
                    .opacity(animate ? 0 : 0.95)
                    .animation(
                        .easeIn(duration: p.duration).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            // 첫 저장 버그 수정: 초기 상태 렌더링 후 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}
