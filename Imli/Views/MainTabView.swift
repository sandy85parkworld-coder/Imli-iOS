import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var savedVM   = SavedViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    var body: some View {
        TabView {
            ScanTabView(historyVM: historyVM)
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .tag(0)

            HistoryView(historyVM: historyVM)
                .tabItem { Label("History", systemImage: "clock") }
                .tag(1)

            SavedView(savedVM: savedVM)
                .tabItem { Label("Saved", systemImage: "heart") }
                .tag(2)

            ProfileView(viewModel: profileVM)
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(3)
        }
        .tint(.imliGreen)
        .environmentObject(savedVM)
        .task(id: authService.userId) {
            guard let uid = authService.userId else { return }
            async let h: () = historyVM.loadHistory(userId: uid)
            async let s: () = savedVM.loadSaved(userId: uid)
            async let p: () = profileVM.loadProfile(userId: uid)
            _ = await (h, s, p)
        }
    }
}

// Thin wrapper so ScanView can forward the scanned product to historyVM
struct ScanTabView: View {
    @ObservedObject var historyVM: HistoryViewModel
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ScanView(onProductScanned: { product in
            // History already written to Firestore by ScanViewModel.
            // Prepend locally for instant UI feedback.
            historyVM.history.insert(product, at: 0)
        })
    }
}
