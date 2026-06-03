import SwiftUI

// MARK: - Splash

struct SplashView: View {
    @State private var bounce: CGFloat = 0
    @State private var pulse: CGFloat = 1
    @State private var rotate: Double = 0
    @State private var wordmarkVisible = false
    @State private var mascotVisible = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF8E7"), Color(hex: "#FFE0B2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("ImliMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 280)
                    .scaleEffect(mascotVisible ? pulse : 0.6)
                    .rotationEffect(.degrees(rotate))
                    .offset(y: bounce)
                    .opacity(mascotVisible ? 1 : 0)
                    .shadow(color: Color(hex: "#5D2E0C").opacity(0.18), radius: 18, y: 12)

                VStack(spacing: 6) {
                    Text("Imli")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#5D2E0C"))
                    Text("Eat Smart, Live Better")
                        .font(ImliFont.callout())
                        .foregroundColor(Color(hex: "#8B4513").opacity(0.7))
                }
                .opacity(wordmarkVisible ? 1 : 0)
                .offset(y: wordmarkVisible ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                mascotVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                wordmarkVisible = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bounce = -10
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = 1.04
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                rotate = 3
            }
        }
    }
}

// MARK: - App Icon Export View
// Use this preview to capture a 1024×1024 PNG for the AppIcon asset.
// Editor → Export Preview to render at 1x.

struct AppIconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 220, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFF1C9"), Color(hex: "#FFB874")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 1024, height: 1024)

            Image("ImliMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 820, height: 920)
                .shadow(color: Color(hex: "#5D2E0C").opacity(0.25), radius: 30, y: 18)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview("Splash") {
    SplashView()
}

#Preview("App Icon 1024") {
    AppIconView()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
