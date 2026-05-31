import SwiftUI

struct SavedView: View {
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
