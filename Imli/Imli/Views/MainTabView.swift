import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanTabView(historyVM: historyVM)
                .tabItem {
                    Label("Scan", systemImage: selectedTab == 0 ? "barcode.viewfinder" : "barcode.viewfinder")
                }
                .tag(0)

            HistoryView(historyVM: historyVM)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(1)

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "heart")
                }
                .tag(2)

            ProfileView(viewModel: profileVM)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .tint(.imliGreen)
    }
}

// Thin wrapper so Scan tab can access historyVM
struct ScanTabView: View {
    @ObservedObject var historyVM: HistoryViewModel

    var body: some View {
        ScanView(onProductScanned: { product in
            historyVM.addScan(product)
        })
    }
}
