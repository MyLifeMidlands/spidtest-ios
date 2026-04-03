import SwiftUI

struct RoutingView: View {
    @ObservedObject private var store = RoutingStore.shared
    @State private var newDomain = ""
    @State private var showInfo = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        modeSection
                        presetsSection
                        servicesSection
                        customDomainsSection
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(String(localized: "Routing"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                InfoSheet(title: String(localized: "Split Tunneling"), sections: HelpTopics.splitTunneling)
            }
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                ForEach(RoutingMode.allCases, id: \.self) { mode in
                    Button {
                        store.config.mode = mode
                        store.save()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: mode.icon)
                                .foregroundStyle(store.config.mode == mode ? Theme.Colors.primary : Theme.Colors.textSecondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.label)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(mode.description)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Spacer()

                            if store.config.mode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if mode != RoutingMode.allCases.last {
                        Divider().background(Theme.Colors.surfaceLight)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(icon: "wand.and.stars", title: String(localized: "Ready-made scenarios"))

            ForEach(RoutingPreset.allPresets) { preset in
                Button {
                    store.applyPreset(preset)
                } label: {
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    if !preset.countries.isEmpty {
                                        ForEach(preset.countries.prefix(3), id: \.self) { code in
                                            Text(flagEmoji(for: code))
                                        }
                                    }
                                    Text(preset.name)
                                        .font(Theme.Fonts.body)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                }
                                Text(preset.description)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Spacer()

                            if store.config.selectedPresetID == preset.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Layout.screenPadding)
            }
        }
    }

    // MARK: - Services

    private var servicesSection: some View {
        VStack(spacing: 8) {
            sectionHeader(icon: "app.badge", title: String(localized: "Services"))

            // Hint based on current mode
            servicesHint
                .padding(.horizontal, Theme.Layout.screenPadding)

            GlassCard {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(RoutingService.all) { service in
                        Button {
                            store.toggleService(service.name)
                        } label: {
                            HStack(spacing: 6) {
                                if store.config.selectedServiceNames.contains(service.name) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.Colors.primary)
                                        .font(.system(size: 14))
                                }
                                Image(systemName: service.icon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text(service.name)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(store.config.selectedServiceNames.contains(service.name) ? Theme.Colors.primary.opacity(0.15) : Theme.Colors.surfaceLight.opacity(0.5))
                            )
                        }
                        .disabled(store.config.mode == .allThroughVPN)
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.screenPadding)
            .opacity(store.config.mode == .allThroughVPN ? 0.4 : 1)
        }
    }

    // MARK: - Custom Domains

    private var customDomainsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(icon: "link", title: String(localized: "Custom domains"))

            GlassCard {
                VStack(spacing: 12) {
                    HStack {
                        TextField(String(localized: "example.com"), text: $newDomain)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)

                        Button {
                            store.addCustomDomain(newDomain)
                            newDomain = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Theme.Colors.primary)
                                .font(.system(size: 24))
                        }
                        .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty || store.config.mode == .allThroughVPN)
                    }

                    if !store.config.customDomains.isEmpty {
                        Divider().background(Theme.Colors.surfaceLight)

                        ForEach(store.config.customDomains, id: \.self) { domain in
                            HStack {
                                Text(domain)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Button {
                                    store.removeCustomDomain(domain)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Theme.Colors.error)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.screenPadding)
        }
    }

    // MARK: - Services Hint

    private var servicesHint: some View {
        HStack(spacing: 8) {
            Image(systemName: servicesHintIcon)
                .foregroundStyle(servicesHintColor)
                .font(.system(size: 14))
            Text(servicesHintText)
                .font(Theme.Fonts.caption)
                .foregroundStyle(servicesHintColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(servicesHintColor.opacity(0.1))
        )
    }

    private var servicesHintText: String {
        switch store.config.mode {
        case .allThroughVPN:
            return String(localized: "All traffic goes through VPN. Service selection is not used in this mode.")
        case .allExceptSelected:
            return String(localized: "Selected services will bypass VPN and connect directly.")
        case .onlySelected:
            return String(localized: "Selected services will go through VPN. Everything else — directly.")
        }
    }

    private var servicesHintIcon: String {
        switch store.config.mode {
        case .allThroughVPN: return "info.circle"
        case .allExceptSelected: return "arrow.right.circle"
        case .onlySelected: return "shield.checkered"
        }
    }

    private var servicesHintColor: Color {
        switch store.config.mode {
        case .allThroughVPN: return Theme.Colors.textSecondary
        case .allExceptSelected: return Theme.Colors.warning
        case .onlySelected: return Theme.Colors.primary
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.primary)
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 0x1F1E6
        let aValue = UInt32(UnicodeScalar("A").value)
        let chars = code.uppercased().unicodeScalars.compactMap { scalar -> Character? in
            guard let s = UnicodeScalar(base + scalar.value - aValue) else { return nil }
            return Character(s)
        }
        return chars.count == 2 ? String(chars) : code
    }
}
