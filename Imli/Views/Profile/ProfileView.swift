import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService
    @State private var showEditProfile = false
    @State private var showAddMember = false
    @State private var memberToEdit: FamilyMember?

    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection
                statsSection

                Section {
                    preferencesContent
                } header: {
                    HStack {
                        Text("Diet Preferences")
                        Spacer()
                        Text("Tap to toggle")
                            .font(ImliFont.caption2())
                            .foregroundColor(.imliSecondary)
                    }
                }

                Section {
                    familyContent
                    addMemberButton
                } header: {
                    HStack {
                        Text("Family Members")
                        Spacer()
                        Button {
                            showAddMember = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.imliGreen)
                                .font(.system(size: 18))
                        }
                    }
                }

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit")
                            .foregroundColor(.imliGreen)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(
                    currentName: viewModel.profile.name,
                    onSave: { name in
                        if let uid = authService.userId {
                            viewModel.updateName(name, userId: uid)
                        }
                    }
                )
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberSheet { member in
                    if let uid = authService.userId {
                        viewModel.addFamilyMember(member, userId: uid)
                    }
                }
            }
            .sheet(item: $memberToEdit) { member in
                AddFamilyMemberSheet(editing: member) { updated in
                    if let uid = authService.userId {
                        viewModel.deleteFamilyMember(id: member.id, userId: uid)
                        viewModel.addFamilyMember(updated, userId: uid)
                    }
                }
            }
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
                    Text(viewModel.profile.name.isEmpty ? "🙂" : String(viewModel.profile.name.prefix(1)))
                        .font(.system(size: 28, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.profile.name.isEmpty ? "Your Name" : viewModel.profile.name)
                        .font(ImliFont.title3())
                        .foregroundColor(viewModel.profile.name.isEmpty ? .imliSecondary : .primary)
                    Text("\(viewModel.profile.totalScans) scans · \(viewModel.profile.familyMembers.count) family members")
                        .font(ImliFont.footnote())
                        .foregroundColor(.imliSecondary)
                }
                Spacer()
                Image(systemName: "pencil.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.imliSecondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture { showEditProfile = true }
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

    // MARK: - Diet Preferences

    private var preferencesContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(UserProfile.DietPreference.allCases, id: \.self) { pref in
                let isActive = viewModel.profile.dietPreferences.contains(pref)
                Button {
                    if let uid = authService.userId {
                        viewModel.togglePreference(pref, userId: uid)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13))
                            .foregroundColor(isActive ? .imliGreen : .imliSecondary)
                        Text(pref.rawValue)
                            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? .imliGreen : .imliSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#C7C7CC"))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { memberToEdit = member }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    if let uid = authService.userId {
                        viewModel.deleteFamilyMember(id: member.id, userId: uid)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var addMemberButton: some View {
        Button {
            showAddMember = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.imliGreen)
                Text("Add Family Member")
                    .font(ImliFont.callout())
                    .foregroundColor(.imliGreen)
            }
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

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: currentName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.imliGreenLight)
                                .frame(width: 56, height: 56)
                            Text(name.isEmpty ? "🙂" : String(name.prefix(1)))
                                .font(.system(size: 26, weight: .semibold))
                        }
                        TextField("Your name", text: $name)
                            .font(ImliFont.title3())
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("This name appears on your profile and scan history.")
                        .font(ImliFont.caption2())
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.imliSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.imliGreen)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Add / Edit Family Member Sheet

struct AddFamilyMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var ageGroup: FamilyMember.AgeGroup
    @State private var selectedEmoji: String
    @State private var dietPreferences: Set<UserProfile.DietPreference>

    let isEditing: Bool
    let onSave: (FamilyMember) -> Void

    private static let emojisByAge: [FamilyMember.AgeGroup: [String]] = [
        .toddler: ["👶", "🍼", "🧸"],
        .child:   ["🧒", "👦", "👧", "🎒"],
        .teen:    ["🧑", "👱", "🎮", "📱"],
        .adult:   ["👨", "👩", "🧔", "👱‍♀️", "🧑‍💻", "🧑‍🍳"],
        .senior:  ["👴", "👵", "🧓"]
    ]

    init(editing member: FamilyMember? = nil, onSave: @escaping (FamilyMember) -> Void) {
        _name            = State(initialValue: member?.name ?? "")
        _ageGroup        = State(initialValue: member?.ageGroup ?? .adult)
        _selectedEmoji   = State(initialValue: member?.emoji ?? "👨")
        _dietPreferences = State(initialValue: member?.dietPreferences ?? [])
        isEditing        = member != nil
        self.onSave      = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Ravi, Mom, Baby…", text: $name)
                }

                Section("Age Group") {
                    Picker("Age Group", selection: $ageGroup) {
                        ForEach(FamilyMember.AgeGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: ageGroup) { _, newGroup in
                        selectedEmoji = Self.emojisByAge[newGroup]?.first ?? "👤"
                    }
                }

                Section("Avatar") {
                    let options = Self.emojisByAge[ageGroup] ?? ["👤"]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(options, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 52, height: 52)
                                .background(selectedEmoji == emoji ? Color.imliGreenLight : Color.imliSurface)
                                .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ImliRadius.md)
                                        .strokeBorder(selectedEmoji == emoji ? Color.imliGreen : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture { selectedEmoji = emoji }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(UserProfile.DietPreference.allCases, id: \.self) { pref in
                            let isActive = dietPreferences.contains(pref)
                            Button {
                                if isActive { dietPreferences.remove(pref) }
                                else        { dietPreferences.insert(pref) }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(isActive ? .imliGreen : .imliSecondary)
                                    Text(pref.rawValue)
                                        .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                                        .foregroundColor(isActive ? .imliGreen : .imliSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
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
                } header: {
                    Text("Diet Preferences")
                } footer: {
                    Text("Used to analyse scan results specifically for this member.")
                }
            }
            .navigationTitle(isEditing ? "Edit Member" : "Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.imliSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Update" : "Add") {
                        let member = FamilyMember(
                            name:             name.trimmingCharacters(in: .whitespaces),
                            ageGroup:         ageGroup,
                            emoji:            selectedEmoji,
                            dietPreferences:  dietPreferences
                        )
                        onSave(member)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.imliGreen)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
