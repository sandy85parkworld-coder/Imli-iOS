import SwiftUI

struct ResultView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var savedVM: SavedViewModel
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: ResultTab = .safety

    enum ResultTab: String, CaseIterable {
        case safety = "Safety"
        case nutrition = "Nutrition"
        case ingredients = "Ingredients"
        case alternatives = "Alternatives"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    productHeader
                    tabPicker
                    tabContent
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                }
            }
            .background(Color.imliSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Scan")
                        }
                        .foregroundColor(.imliBlue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            guard let uid = authService.userId else { return }
                            Task { await savedVM.toggleSave(product, userId: uid) }
                        } label: {
                            Image(systemName: savedVM.isSaved(product.barcode) ? "heart.fill" : "heart")
                                .foregroundColor(savedVM.isSaved(product.barcode) ? .imliRed : .imliBlue)
                                .animation(.spring(duration: 0.25), value: savedVM.isSaved(product.barcode))
                        }
                        Button {
                            // Share action placeholder
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.imliBlue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Product Header
    private var productHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Product image placeholder
                Text(product.imageEmoji)
                    .font(.system(size: 36))
                    .frame(width: 64, height: 64)
                    .background(Color.imliSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ImliRadius.md)
                            .strokeBorder(Color.imliSeparator, lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(ImliFont.headline())
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(product.brand)
                        .font(ImliFont.footnote())
                        .foregroundColor(.imliSecondary)
                    HStack(spacing: 6) {
                        VegStatusPill(status: product.vegStatus)
                        if product.fssaiApproved { FSSAIBadge() }
                    }
                }

                Spacer()

                GradeBadge(grade: product.grade, size: .large)
            }
            .padding(16)
            .background(Color.imliCard)

            // Grade summary strip
            HStack {
                Image(systemName: product.grade.systemIcon)
                    .font(.system(size: 13))
                    .foregroundColor(product.grade.color)
                Text(product.grade.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(product.grade.color)
                Text("·")
                    .foregroundColor(.imliSecondary)
                Text("\(product.flags.filter { $0.severity == .danger }.count) critical issues detected")
                    .font(ImliFont.caption1())
                    .foregroundColor(.imliSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(product.grade.backgroundColor)
        }
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ResultTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .imliGreen : .imliSecondary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(selectedTab == tab ? Color.imliGreen : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
        }
        .background(Color.imliCard)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .safety:     safetyTab
        case .nutrition:  nutritionTab
        case .ingredients: ingredientsTab
        case .alternatives: alternativesTab
        }
    }

    // MARK: - Safety Tab
    private var safetyTab: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Ingredient Flags")

            CardContainer {
                VStack(spacing: 6) {
                    ForEach(product.flags) { flag in
                        FlagRow(flag: flag)
                    }
                }
                .padding(12)
            }

            SectionHeader(title: "Kid Safety")
            CardContainer {
                KidSafetyBanner(kidSafe: product.kidSafe, note: product.kidSafeNote)
                    .padding(12)
            }
        }
    }

    // MARK: - Nutrition Tab
    private var nutritionTab: some View {
        let n = product.nutrition
        return VStack(spacing: 0) {
            SectionHeader(title: "Per 100g · Serving: \(n.servingSize)")

            CardContainer {
                VStack(spacing: 0) {
                    nutritionRow("Energy", value: "\(Int(n.energy)) kcal", isLast: false)
                    nutritionRow("Protein", value: "\(n.protein)g", isLast: false)
                    nutritionRow("Total Carbohydrates", value: "\(n.carbs)g", isLast: false)
                    nutritionRow("  of which Sugars", value: "\(n.totalSugars)g",
                                 highlight: n.totalSugars > 20 ? .imliRed : nil, isLast: false)
                    if let added = n.addedSugars {
                        nutritionRow("  of which Added Sugars", value: "\(added)g",
                                     highlight: added > 10 ? .imliOrange : nil, isLast: false)
                    }
                    nutritionRow("Total Fat", value: "\(n.totalFat)g", isLast: false)
                    nutritionRow("  Saturated Fat", value: "\(n.saturatedFat)g", isLast: false)
                    nutritionRow("  Trans Fat", value: "\(n.transFat)g",
                                 highlight: n.transFat > 0 ? .imliRed : nil, isLast: false)
                    nutritionRow("Sodium", value: "\(Int(n.sodium))mg",
                                 highlight: n.sodium > 600 ? .imliOrange : nil, isLast: true)
                }
            }
        }
    }

    private func nutritionRow(_ label: String, value: String, highlight: Color? = nil, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(ImliFont.subheadline())
                    .foregroundColor(label.hasPrefix("  ") ? .imliSecondary : .primary)
                Spacer()
                Text(value)
                    .font(ImliFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(highlight ?? .primary)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
            if !isLast { Divider().padding(.leading, 16) }
        }
    }

    // MARK: - Ingredients Tab
    private var ingredientsTab: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Full Ingredient List")
            CardContainer {
                Text(product.ingredients)
                    .font(ImliFont.callout())
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            SectionHeader(title: "Barcode")
            CardContainer {
                HStack {
                    Image(systemName: "barcode")
                        .font(.system(size: 18))
                        .foregroundColor(.imliSecondary)
                    Text(product.barcode)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(16)
            }
        }
    }

    // MARK: - Alternatives Tab
    private var alternativesTab: some View {
        VStack(spacing: 0) {
            if product.alternatives.isEmpty {
                SectionHeader(title: "Alternatives")
                CardContainer {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.imliGreen)
                        Text("This is already a top choice!")
                            .font(ImliFont.subheadline())
                            .foregroundColor(.primary)
                        Text("No better alternatives found in our database.")
                            .font(ImliFont.caption1())
                            .foregroundColor(.imliSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
            } else {
                SectionHeader(title: "Better Choices")
                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(Array(product.alternatives.enumerated()), id: \.element.id) { i, alt in
                            AlternativeRow(product: alt)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            if i < product.alternatives.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                }
            }
        }
    }
}
