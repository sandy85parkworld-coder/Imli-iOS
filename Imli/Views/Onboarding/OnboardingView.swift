import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🌿",
            title: "Know What's in Your Food",
            description: "Imli scans any barcode and instantly reveals every ingredient — the good, the bad, and what brands hide from you.",
            accent: Color(hex: "#2E7D32")
        ),
        OnboardingPage(
            emoji: "🔴🟢",
            title: "Veg / Non-Veg, Verified",
            description: "Goes beyond the green dot. AI detects hidden animal-derived ingredients like gelatin, bone char, and animal extracts.",
            accent: Color(hex: "#C62828")
        ),
        OnboardingPage(
            emoji: "⚠️",
            title: "Smart Ingredient Alerts",
            description: "Instantly flags trans fats, palm oil, artificial colours, harmful preservatives, and additives — so you always know what you're eating.",
            accent: Color(hex: "#E65100")
        ),
        OnboardingPage(
            emoji: "👨‍👩‍👧",
            title: "Safe for Your Family",
            description: "Create profiles for your kids. Imli flags ingredients harmful to toddlers and children with a dedicated Kid Safety mode.",
            accent: Color(hex: "#1565C0")
        )
    ]

    var body: some View {
        ZStack {
            Color(hex: "#FAFFFE").ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation { currentPage = pages.count - 1 }
                        }
                        .font(ImliFont.callout())
                        .foregroundColor(.imliSecondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                    } else {
                        Color.clear.frame(height: 44).padding(.top, 60)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? pages[currentPage].accent : Color.imliSeparator)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA
                VStack(spacing: 12) {
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            appState.hasCompletedOnboarding = true
                        }
                    } label: {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started Free")
                                .font(ImliFont.headline())
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pages[currentPage].accent)
                        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
                    }
                    .padding(.horizontal, 24)

                    if currentPage == pages.count - 1 {
                        Button("I already have an account") {
                            appState.hasCompletedOnboarding = true
                        }
                        .font(ImliFont.footnote())
                        .foregroundColor(.imliSecondary)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
    let accent: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            // Illustration area
            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.08))
                    .frame(width: 220, height: 220)
                Circle()
                    .fill(page.accent.opacity(0.05))
                    .frame(width: 280, height: 280)
                Text(page.emoji)
                    .font(.system(size: 90))
            }
            .padding(.bottom, 48)

            Text(page.title)
                .font(ImliFont.title1())
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

            Text(page.description)
                .font(ImliFont.callout())
                .multilineTextAlignment(.center)
                .foregroundColor(.imliSecondary)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}
