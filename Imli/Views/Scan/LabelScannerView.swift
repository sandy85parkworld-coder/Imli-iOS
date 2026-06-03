import SwiftUI
import VisionKit

// MARK: - Container (shown in the label tab of ScanView)

struct LabelScannerContainer: View {
    let onAnalyze: (String) -> Void

    @State private var recognizedText = ""
    @State private var hasText = false
    @State private var isUnavailable = false

    var body: some View {
        ZStack {
            if isUnavailable {
                unavailableView
            } else {
                LabelScannerRepresentable(
                    onTextUpdated: { text in
                        recognizedText = text
                        hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                )
                .ignoresSafeArea()

                // Instruction overlay
                VStack {
                    Text("Point camera at ingredient label")
                        .font(ImliFont.footnote())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.top, 70)

                    Spacer()

                    // Analyze button — enabled once text is detected
                    Button {
                        guard !recognizedText.isEmpty else { return }
                        onAnalyze(recognizedText)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: hasText ? "text.viewfinder" : "viewfinder")
                                .font(.system(size: 16, weight: .semibold))
                            Text(hasText ? "Analyse Ingredients" : "Scanning for text…")
                                .font(ImliFont.callout())
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(hasText ? Color.imliGreen : Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
                        .padding(.horizontal, 24)
                    }
                    .disabled(!hasText)
                    .animation(.easeInOut(duration: 0.25), value: hasText)
                    .padding(.bottom, 110)
                }
            }
        }
        .onAppear {
            isUnavailable = !DataScannerViewController.isAvailable
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("Live Text Not Available")
                .font(ImliFont.subheadline())
                .foregroundColor(.white.opacity(0.6))
            Text("This device or OS version doesn't support live text recognition.")
                .font(ImliFont.caption1())
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - UIViewControllerRepresentable wrapper for DataScannerViewController

struct LabelScannerRepresentable: UIViewControllerRepresentable {
    let onTextUpdated: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTextUpdated: onTextUpdated) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onTextUpdated = onTextUpdated
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController,
                                          coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onTextUpdated: (String) -> Void
        weak var scanner: DataScannerViewController?
        private var items: [RecognizedItem] = []

        init(onTextUpdated: @escaping (String) -> Void) {
            self.onTextUpdated = onTextUpdated
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            items = allItems
            onTextUpdated(collectedText())
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            items = allItems
            onTextUpdated(collectedText())
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didRemove removedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            items = allItems
            onTextUpdated(collectedText())
        }

        private func collectedText() -> String {
            items.compactMap { item -> String? in
                if case .text(let t) = item { return t.transcript }
                return nil
            }.joined(separator: " ")
        }
    }
}
