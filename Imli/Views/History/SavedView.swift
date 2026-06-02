import SwiftUI

struct SavedView: View {
    @ObservedObject var savedVM: SavedViewModel
    @EnvironmentObject var authService: AuthService
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            Group {
                if savedVM.isLoading {
                    ProgressView("Loading saved…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.imliSurface)
                } else if savedVM.saved.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(savedVM.saved) { product in
                            Button { selectedProduct = product } label: {
                                HistoryCard(product: product)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .listRowBackground(Color.imliSurface)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    guard let uid = authService.userId else { return }
                                    Task { await savedVM.toggleSave(product, userId: uid) }
                                } label: {
                                    Label("Remove", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.imliSurface)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.imliSurface)
            .sheet(item: $selectedProduct) { product in
                ResultView(product: product)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundColor(.imliSecondary.opacity(0.5))
            Text("No saved products")
                .font(ImliFont.title3())
                .foregroundColor(.primary)
            Text("Tap the heart icon on any product to save it here")
                .font(ImliFont.callout())
                .foregroundColor(.imliSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.imliSurface)
    }
}
