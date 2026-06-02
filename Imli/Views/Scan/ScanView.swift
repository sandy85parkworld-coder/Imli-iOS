import SwiftUI
import AVFoundation

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var selectedMode: ScanMode = .barcode
    @State private var showingResult = false
    @State private var cameraPermission: CameraPermission = .unknown
    // Search state
    @State private var searchQuery = ""
    @State private var searchResults: [ProductSearchResult] = []
    @State private var isSearching = false
    @State private var searchDebounce: Task<Void, Never>?
    @FocusState private var searchFocused: Bool

    let onProductScanned: (Product) -> Void

    enum ScanMode: String, CaseIterable {
        case barcode = "Barcode"
        case label   = "Label OCR"
        case search  = "Search"
    }

    enum CameraPermission { case unknown, granted, denied }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                switch selectedMode {
                case .barcode:
                    barcodeScannerLayer
                case .label:
                    placeholderCameraLayer(icon: "camera.viewfinder", text: "Snap the ingredients label")
                case .search:
                    searchLayer
                }

                // Overlay UI
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomControls
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingResult) {
                if let product = viewModel.product {
                    ResultView(product: product)
                        .onDisappear {
                            onProductScanned(product)
                            viewModel.reset()
                        }
                }
            }
            .alert("Product Not Found", isPresented: .constant(viewModel.scanState == .notFound)) {
                Button("OK") { viewModel.reset() }
            } message: {
                Text("No product found for barcode \(viewModel.scannedBarcode ?? ""). Try scanning again or search manually.")
            }
            .alert("Error", isPresented: .constant(viewModel.scanState == .error)) {
                Button("OK") { viewModel.reset() }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong. Check your connection.")
            }
            .onChange(of: viewModel.scanState) { _, state in
                if state == .success { showingResult = true }
            }
            .onAppear { checkCameraPermission() }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Text("Scan Product")
                .font(ImliFont.headline())
                .foregroundColor(.white)
            Spacer()
            Button {
                viewModel.torchOn.toggle()
            } label: {
                Image(systemName: viewModel.torchOn ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.torchOn ? Color(hex: "#FFD60A") : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Barcode Scanner Layer
    private var barcodeScannerLayer: some View {
        ZStack {
            // Live camera
            BarcodeScannerView(
                onBarcodeFound: { barcode in
                    Task { await viewModel.lookupBarcode(barcode, userId: authService.userId) }
                },
                torchOn: $viewModel.torchOn
            )
            .ignoresSafeArea()

            // Viewfinder overlay
            GeometryReader { geo in
                let w = geo.size.width * 0.72
                let h: CGFloat = 180
                let x = (geo.size.width - w) / 2
                let y = (geo.size.height - h) / 2

                ZStack {
                    // Dark vignette
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .mask(
                            Rectangle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .frame(width: w, height: h)
                                        .blendMode(.destinationOut)
                                )
                        )

                    // Frame corners
                    Group {
                        cornerMark(at: CGPoint(x: x, y: y), corner: .topLeft)
                        cornerMark(at: CGPoint(x: x + w - 22, y: y), corner: .topRight)
                        cornerMark(at: CGPoint(x: x, y: y + h - 22), corner: .bottomLeft)
                        cornerMark(at: CGPoint(x: x + w - 22, y: y + h - 22), corner: .bottomRight)
                    }

                    // Animated scan laser
                    if viewModel.scanState != .loading {
                        ScanLaserView(width: w - 24)
                            .position(x: geo.size.width / 2, y: y + h / 2)
                    }

                    // Loading spinner
                    if viewModel.scanState == .loading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                            .position(x: geo.size.width / 2, y: y + h / 2)
                    }
                }
            }

            // Hint text
            VStack {
                Spacer()
                Spacer()
                Text(viewModel.scanState == .loading ? "Analysing ingredients..." : "Align barcode within the frame")
                    .font(ImliFont.footnote())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 170)
            }
        }
    }

    // MARK: - Corner Mark
    private func cornerMark(at point: CGPoint, corner: Corner) -> some View {
        let length: CGFloat = 22
        let thickness: CGFloat = 3
        let color = Color(hex: "#34C759")

        return ZStack {
            // Horizontal
            Rectangle()
                .fill(color)
                .frame(width: length, height: thickness)
                .offset(
                    x: corner.xOffset(length: length, thickness: thickness),
                    y: corner.yOffset(length: length, thickness: thickness)
                )
            // Vertical
            Rectangle()
                .fill(color)
                .frame(width: thickness, height: length)
                .offset(
                    x: corner.xOffset(length: length, thickness: thickness),
                    y: corner.yOffset2(length: length, thickness: thickness)
                )
        }
        .position(x: point.x + length / 2, y: point.y + length / 2)
    }

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
        func xOffset(length: CGFloat, thickness: CGFloat) -> CGFloat {
            switch self {
            case .topLeft, .bottomLeft: return 0
            case .topRight, .bottomRight: return 0
            }
        }
        func yOffset(length: CGFloat, thickness: CGFloat) -> CGFloat { 0 }
        func yOffset2(length: CGFloat, thickness: CGFloat) -> CGFloat { 0 }
    }

    // MARK: - Placeholder camera
    private func placeholderCameraLayer(icon: String, text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            Text(text)
                .font(ImliFont.callout())
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Search layer
    private var searchLayer: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: isSearching ? "arrow.clockwise" : "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .rotationEffect(isSearching ? .degrees(360) : .zero)
                    .animation(isSearching ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSearching)

                TextField("", text: $searchQuery, prompt: Text("Search product name or brand…").foregroundColor(.white.opacity(0.4)))
                    .foregroundColor(.white)
                    .font(ImliFont.callout())
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { triggerSearch() }
                    .onChange(of: searchQuery) { _, query in
                        searchDebounce?.cancel()
                        if query.trimmingCharacters(in: .whitespaces).count < 2 {
                            searchResults = []
                            return
                        }
                        searchDebounce = Task {
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            guard !Task.isCancelled else { return }
                            triggerSearch()
                        }
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                        searchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .onAppear { searchFocused = true }

            // Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    if searchResults.isEmpty && !isSearching && searchQuery.count >= 2 {
                        noResultsView
                    } else {
                        ForEach(searchResults) { result in
                            searchResultRow(result)
                                .padding(.horizontal, 20)
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private func searchResultRow(_ result: ProductSearchResult) -> some View {
        Button {
            searchFocused = false
            Task { await viewModel.lookupBarcode(result.id, userId: authService.userId) }
        } label: {
            HStack(spacing: 12) {
                Text(result.emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: ImliRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(ImliFont.subheadline())
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if !result.brand.isEmpty {
                        Text(result.brand)
                            .font(ImliFont.caption1())
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var noResultsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text("No products found for "\(searchQuery)"")
                .font(ImliFont.footnote())
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func triggerSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else { return }
        isSearching = true
        Task {
            do {
                let results = try await ProductAPIService.shared.searchProducts(query: query)
                searchResults = results
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 0) {
            // Mode picker
            HStack(spacing: 8) {
                ForEach(ScanMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedMode = mode }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: modeIcon(mode))
                                .font(.system(size: 12))
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedMode == mode ? Color.white : Color.white.opacity(0.1))
                        .foregroundColor(selectedMode == mode ? .black : .white)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
    }

    private func modeIcon(_ mode: ScanMode) -> String {
        switch mode {
        case .barcode: return "barcode.viewfinder"
        case .label:   return "camera"
        case .search:  return "magnifyingglass"
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraPermission = .granted
        case .denied, .restricted: cameraPermission = .denied
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .granted : .denied
                }
            }
        @unknown default: break
        }
    }
}

// MARK: - Animated Laser
struct ScanLaserView: View {
    let width: CGFloat
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#34C759"))
            .frame(width: width, height: 2)
            .shadow(color: Color(hex: "#34C759").opacity(0.8), radius: 4, y: 0)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                ) { offset = 60 }
            }
    }
}
