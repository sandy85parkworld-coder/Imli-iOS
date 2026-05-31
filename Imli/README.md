# 🌿 Imli — India's Food Safety Scanner
### Native iOS App · SwiftUI · AVFoundation

---

## Project Structure

```
Imli/
├── App/
│   ├── ImliApp.swift          ← @main entry point
│   ├── AppState.swift         ← Global ObservableObject
│   └── Info.plist             ← Camera permission + bundle config
│
├── Theme/
│   └── DesignSystem.swift     ← Colors, typography, spacing tokens
│
├── Models/
│   └── Models.swift           ← Product, SafetyGrade, VegStatus, FamilyMember
│
├── ViewModels/
│   └── ViewModels.swift       ← ScanViewModel, HistoryViewModel, ProfileViewModel
│
├── Services/
│   └── BarcodeScannerView.swift  ← AVFoundation camera UIViewRepresentable
│
├── Components/
│   └── Components.swift       ← GradeBadge, VegStatusPill, FlagRow, HistoryCard…
│
└── Views/
    ├── MainTabView.swift       ← Root tab bar
    ├── Onboarding/
    │   └── OnboardingView.swift
    ├── Scan/
    │   └── ScanView.swift      ← Camera + mode switcher
    ├── Result/
    │   └── ResultView.swift    ← Safety / Nutrition / Ingredients / Alternatives
    ├── History/
    │   ├── HistoryView.swift
    │   └── SavedView.swift
    └── Profile/
        └── ProfileView.swift
```

---

## Setup in Xcode

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- Swift 5.9+
- Physical iPhone (camera features need real device)

### Steps

1. **Open Xcode → Create a new project**
   - Choose: App template
   - Interface: SwiftUI
   - Language: Swift
   - Product Name: `Imli`
   - Bundle ID: `com.imli.foodscanner`

2. **Replace all generated files** with the files from this project.
   - Delete `ContentView.swift`
   - Add all folders and files from `Imli/` into your Xcode project
   - Make sure "Add to target: Imli" is checked for each file

3. **Replace Info.plist** with the provided one (or manually add):
   ```
   NSCameraUsageDescription = "Imli needs camera access to scan product barcodes."
   ```

4. **Set Deployment Target** to iOS 17.0 in project settings.

5. **Build & Run** on a physical device (camera required for scan).

---

## Key Architecture Decisions

| Pattern | Choice | Reason |
|---|---|---|
| State management | `@StateObject` + `@EnvironmentObject` | Native SwiftUI, no dependencies |
| Navigation | `NavigationStack` | iOS 16+ type-safe push navigation |
| Camera | `AVFoundation` via `UIViewRepresentable` | Full barcode scanning control |
| Barcode types | EAN-13, EAN-8, UPC-E, Code128, QR | Covers all Indian packaged food |
| Design system | Custom `Color` extensions + `ImliFont` | Consistent tokens across app |
| Data | Mock data + async/await lookup | Easily replace with real API |

---

## Connecting a Real API

Replace the mock lookup in `ScanViewModel.lookupBarcode()`:

```swift
func lookupBarcode(_ barcode: String) async {
    scanState = .loading
    
    guard let url = URL(string: "https://api.imli.app/v1/products/\(barcode)") else { return }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let product = try JSONDecoder().decode(Product.self, from: data)
        self.product = product
        self.scanState = .success
    } catch {
        self.scanState = .notFound
    }
}
```

---

## Indian Product Databases to Integrate

| Source | Coverage | Access |
|---|---|---|
| Open Food Facts India | 40,000+ products | Free API |
| FSSAI Approved Additives | Complete list | Government open data |
| ICMR Dietary Guidelines | Nutrient benchmarks | PDF / scrape |
| Community contributions | Crowdsourced | Build in-app |

---

## App Store Checklist

- [x] Camera permission description in Info.plist
- [x] Portrait-only orientation
- [x] Supports iOS 17+
- [ ] App icon (1024×1024 PNG, no alpha)
- [ ] Screenshots for 6.7", 6.1", 5.5" and iPad
- [ ] Privacy Policy URL
- [ ] Age rating: 4+

---

Built with ❤️ for Bharat 🇮🇳
