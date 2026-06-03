import SwiftUI

struct LabelResultView: View {
    let rawText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showFullText = false

    private var analysis: ProductAPIService.LabelAnalysis {
        ProductAPIService.shared.analyzeIngredients(rawText)
    }

    private var dangerCount: Int { analysis.flags.filter { $0.severity == .danger }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    summaryHeader
                    VStack(spacing: 0) {
                        flagsSection
                        vegStatusSection
                        capturedTextSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.imliSurface)
            .navigationTitle("Label Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.imliGreen)
                }
            }
        }
    }

    // MARK: - Summary header

    private var summaryHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.imliSurface)
                        .frame(width: 64, height: 64)
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(.imliGreen)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredient Label Scan")
                        .font(ImliFont.headline())
                        .foregroundColor(.primary)
                    Text("Analysed via camera OCR")
                        .font(ImliFont.footnote())
                        .foregroundColor(.imliSecondary)
                    VegStatusPill(status: analysis.vegStatus)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.imliCard)

            HStack {
                Image(systemName: dangerCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(dangerCount > 0 ? .imliRed : .imliGreen)
                Text(dangerCount > 0
                    ? "\(dangerCount) critical concern\(dangerCount > 1 ? "s" : "") detected"
                    : "No critical concerns detected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(dangerCount > 0 ? .imliRed : .imliGreen)
                Spacer()
                Text("Note: No nutrition data from OCR")
                    .font(ImliFont.caption2())
                    .foregroundColor(.imliSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(dangerCount > 0 ? Color.imliRedLight : Color.imliGreenLight)
        }
    }

    // MARK: - Flags

    private var flagsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Ingredient Flags")
            CardContainer {
                VStack(spacing: 6) {
                    ForEach(analysis.flags) { flag in
                        FlagRow(flag: flag)
                    }
                }
                .padding(12)
            }
        }
    }

    // MARK: - Veg status

    private var vegStatusSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Dietary Status")
            CardContainer {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(analysis.vegStatus.dotColor, lineWidth: 2)
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(analysis.vegStatus.dotColor)
                            .frame(width: 7, height: 7)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(analysis.vegStatus.rawValue)
                            .font(ImliFont.subheadline())
                            .fontWeight(.semibold)
                            .foregroundColor(analysis.vegStatus.color)
                        Text("Detected from ingredient keywords")
                            .font(ImliFont.caption1())
                            .foregroundColor(.imliSecondary)
                    }
                    Spacer()
                }
                .padding(14)
            }
        }
    }

    // MARK: - Captured text

    private var capturedTextSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Captured Text")
            CardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    Text(showFullText
                         ? analysis.ingredients
                         : String(analysis.ingredients.prefix(300)))
                        .font(ImliFont.callout())
                        .foregroundColor(.primary)
                        .lineSpacing(4)

                    if analysis.ingredients.count > 300 {
                        Button {
                            withAnimation { showFullText.toggle() }
                        } label: {
                            Text(showFullText ? "Show less" : "Show more…")
                                .font(ImliFont.footnote())
                                .foregroundColor(.imliGreen)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }

            // Disclaimer
            Text("OCR accuracy depends on label clarity, lighting, and text size. Results are indicative only.")
                .font(ImliFont.caption2())
                .foregroundColor(.imliSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
    }
}
