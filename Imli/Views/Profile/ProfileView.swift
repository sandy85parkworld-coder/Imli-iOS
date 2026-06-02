import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            List {
                // Profile header (not in a section for full-width)
                profileHeaderSection

                // Stats
                statsSection

                // Diet Preferences
                Section {
                    preferencesContent
                } header: {
                    Text("Diet Preferences")
                }

                // Family Members
                Section {
                    familyContent
                } header: {
                    Text("Family Members")
                }

                // App Settings
                Section {
                    settingsRow(icon: "bell", label: "Notifications", color: .red)
                    settingsRow(icon: "globe", label: "Language", color: .blue, detail: "English")
                    settingsRow(icon: "lock.shield", label: "Privacy", color: .imliGreen)
                    settingsRow(icon: "questionmark.circle", label: "Help & FAQ", color: .orange)
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.imliRed)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            Text("Sign Out")
                                .font(ImliFont.callout())
                                .foregroundColor(.imliRed)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Settings")
                }

                // App info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Imli · Eat Smart, Live Better")
                                .font(ImliFont.caption1())
                                .foregroundColor(.imliSecondary)
                            Text("Version 1.0.0 · Powered by Open Food Facts")
                                .font(ImliFont.caption2())
                                .foregroundColor(.imliSecondary.opacity(0.7))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.imliSurface)
        }
    }

    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.imliGreenLight)
                        .frame(width: 60, height: 60)
                    Text("👨")
                        .font(.system(size: 32))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.profile.name)
                        .font(ImliFont.title3())
                        .foregroundColor(.primary)
                    Text("Pure Vegetarian · \(viewModel.profile.totalScans) scans")
                        .font(ImliFont.footnote())
                        .foregroundColor(.imliSecondary)
                }
                Spacer()
                Text("Pro")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.imliGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        Capsule().strokeBorder(Color.imliGreen, lineWidth: 1)
                    )
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Stats
    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                statCard(value: "\(viewModel.profile.totalScans)", label: "Total Scans", color: Color(hex: "#006874"))
                statCard(value: "\(Int(viewModel.profile.safePercentage))%", label: "Safe Products", color: .imliGreen)
                statCard(value: "\(viewModel.profile.familyMembers.count)", label: "Family", color: Color(hex: "#6750A4"))
            }
            .listRowBackground(Color.imliSurface)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(ImliFont.caption2())
                .foregroundColor(.imliSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
    }

    // MARK: - Preferences
    private var preferencesContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(UserProfile.DietPreference.allCases, id: \.self) { pref in
                let isActive = viewModel.profile.dietPreferences.contains(pref)
                Button {
                    if let uid = authService.userId {
                        viewModel.togglePreference(pref, userId: uid)
                    }
                } label: {
                    Text(pref.rawValue)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .foregroundColor(isActive ? .imliGreen : .imliSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isActive ? Color.imliGreenLight : Color.imliSurface)
                        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: ImliRadius.md)
                                .strokeBorder(isActive ? Color.imliGreenMid : Color.imliSeparator, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Family Members
    private var familyContent: some View {
        ForEach(viewModel.profile.familyMembers) { member in
            HStack(spacing: 12) {
                Text(member.emoji)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Color.imliGreenLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(ImliFont.subheadline())
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(member.ageGroup.rawValue)
                        .font(ImliFont.caption1())
                        .foregroundColor(.imliSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.imliGreen)
                    .font(.system(size: 18))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Settings Row
    private func settingsRow(icon: String, label: String, color: Color, detail: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(ImliFont.callout())
                .foregroundColor(.primary)

            Spacer()

            if let detail {
                Text(detail)
                    .font(ImliFont.callout())
                    .foregroundColor(.imliSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#C7C7CC"))
        }
    }
}
