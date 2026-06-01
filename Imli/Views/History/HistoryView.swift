import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyVM: HistoryViewModel
    @State private var selectedProduct: Product?
    @State private var searchText = ""

    private var filtered: [Product] {
        guard !searchText.isEmpty else { return historyVM.history }
        return historyVM.history.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if historyVM.history.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { product in
                            Button {
                                selectedProduct = product
                            } label: {
                                HistoryCard(product: product)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .listRowBackground(Color.imliSurface)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.imliSurface)
                    .searchable(text: $searchText, prompt: "Search scanned products")
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.imliSurface)
            .sheet(item: $selectedProduct) { product in
                ResultView(product: product)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundColor(.imliSecondary.opacity(0.5))
            Text("No scans yet")
                .font(ImliFont.title3())
                .foregroundColor(.primary)
            Text("Products you scan will appear here")
                .font(ImliFont.callout())
                .foregroundColor(.imliSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.imliSurface)
    }
}
