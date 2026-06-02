import SwiftUI

// MARK: - Grade Badge
struct GradeBadge: View {
    let grade: SafetyGrade
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large
        var dimension: CGFloat {
            switch self { case .small: 32; case .medium: 52; case .large: 72 }
        }
        var fontSize: CGFloat {
            switch self { case .small: 14; case .medium: 22; case .large: 32 }
        }
        var captionSize: CGFloat {
            switch self { case .small: 0; case .medium: 9; case .large: 11 }
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(grade.backgroundColor)
                .frame(width: size.dimension, height: size.dimension)
            Circle()
                .strokeBorder(grade.borderColor, lineWidth: size == .large ? 3 : 2)
                .frame(width: size.dimension, height: size.dimension)
            VStack(spacing: 0) {
                Text(grade.rawValue)
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(grade.color)
                if size != .small {
                    Text("grade")
                        .font(.system(size: size.captionSize))
                        .foregroundColor(.imliSecondary)
                }
            }
        }
    }
}

// MARK: - Veg Status Pill
struct VegStatusPill: View {
    let status: VegStatus

    var body: some View {
        HStack(spacing: 5) {
            // Standard veg/non-veg square dot
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(status.dotColor, lineWidth: 1.5)
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(status.dotColor)
                    .frame(width: 5, height: 5)
            }
            Text(status.rawValue)
                .font(ImliFont.caption1())
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: ImliRadius.pill)
                .strokeBorder(status.borderColor, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Flag Row
struct FlagRow: View {
    let flag: IngredientFlag

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: flag.severity.icon)
                .font(.system(size: 14))
                .foregroundColor(flag.severity.dotColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(flag.name)
                    .font(ImliFont.footnote())
                    .fontWeight(.semibold)
                    .foregroundColor(flag.severity.color)
                Text(flag.detail)
                    .font(ImliFont.caption2())
                    .foregroundColor(flag.severity.color.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            if let badge = flag.badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(flag.severity.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(flag.severity.backgroundColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(flag.severity.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
    }
}

// MARK: - Nutrition Row
struct NutritionRow: View {
    let label: String
    let value: String
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(ImliFont.subheadline())
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .font(ImliFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 16)

            if !isLast {
                Divider().padding(.leading, 16)
            }
        }
    }
}

// MARK: - Section Header (iOS grouped style)
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.imliSecondary)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card Container
struct CardContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color.imliCard)
            .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
    }
}

// MARK: - Alternative Product Row
struct AlternativeRow: View {
    let product: AlternativeProduct

    var body: some View {
        HStack(spacing: 12) {
            Text(product.imageEmoji)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Color.imliSurface)
                .clipShape(RoundedRectangle(cornerRadius: ImliRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(ImliFont.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(product.brand)
                    .font(ImliFont.caption1())
                    .foregroundColor(.imliSecondary)
            }

            Spacer()

            GradeBadge(grade: product.grade, size: .small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Kid Safety Banner
struct KidSafetyBanner: View {
    let kidSafe: Bool
    let note: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kidSafe ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.system(size: 22))
                .foregroundColor(kidSafe ? .imliGreen : .imliRed)

            VStack(alignment: .leading, spacing: 2) {
                Text(kidSafe ? "Safe for Children" : "Not for Children")
                    .font(ImliFont.footnote())
                    .fontWeight(.bold)
                    .foregroundColor(kidSafe ? .imliGreen : .imliRed)
                if let note {
                    Text(note)
                        .font(ImliFont.caption2())
                        .foregroundColor(kidSafe ? Color(hex: "#388E3C") : Color(hex: "#C62828"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(kidSafe ? Color.imliGreenLight : Color.imliRedLight)
        .overlay(
            RoundedRectangle(cornerRadius: ImliRadius.md)
                .strokeBorder(kidSafe ? Color.imliGreenMid : Color(hex: "#EF9A9A"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
    }
}

// MARK: - Verified Badge
struct FSSAIBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#1565C0"))
            Text("Database Verified")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#1565C0"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "#E3F2FD"))
        .clipShape(Capsule())
    }
}

// MARK: - Scan History Card
struct HistoryCard: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            Text(product.imageEmoji)
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Color.imliSurface)
                .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(ImliFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(product.brand)
                    .font(ImliFont.caption1())
                    .foregroundColor(.imliSecondary)
                HStack(spacing: 6) {
                    VegStatusPill(status: product.vegStatus)
                    Text(timeAgo(product.scannedAt))
                        .font(ImliFont.caption2())
                        .foregroundColor(.imliSecondary)
                }
            }

            Spacer()

            GradeBadge(grade: product.grade, size: .small)
        }
        .padding(12)
        .background(Color.imliCard)
        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
