import SwiftUI

struct ServerListView: View {
    @ObservedObject var serverStore: ServerStore
    @ObservedObject var viewModel: VPNViewModel
    @ObservedObject private var loadBalancer = LoadBalancer.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if serverStore.servers.isEmpty {
                    emptyState
                } else {
                    serverList
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle(String(localized: "Servers"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Ping button
                        if serverStore.servers.count > 1 {
                            Button {
                                Task {
                                    await loadBalancer.measureAllPings(servers: serverStore.servers)
                                }
                            } label: {
                                if loadBalancer.isMeasuring {
                                    ProgressView()
                                        .tint(Theme.Colors.primary)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                            }
                            .disabled(loadBalancer.isMeasuring)
                        }

                        // Add button
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.showAddServer = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(String(localized: "No Servers"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(String(localized: "Add a VLESS server to get started"))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            VombatButton(title: String(localized: "Add Server"), icon: "plus.circle") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showAddServer = true
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var serverList: some View {
        List {
            // Favorites section
            let favorites = serverStore.sortedServers.filter { $0.isFavorite }
            if !favorites.isEmpty {
                Section {
                    ForEach(favorites) { server in
                        serverRow(server)
                            .listRowBackground(Theme.Colors.surface)
                            .listRowSeparatorTint(Theme.Colors.surfaceLight)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text(String(localized: "Favorites"))
                    }
                    .foregroundStyle(Theme.Colors.primary)
                    .font(Theme.Fonts.caption)
                }
            }

            // All servers
            let others = serverStore.sortedServers.filter { !$0.isFavorite }
            Section {
                ForEach(others) { server in
                    serverRow(server)
                        .listRowBackground(Theme.Colors.surface)
                        .listRowSeparatorTint(Theme.Colors.surfaceLight)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        serverStore.remove(id: others[index].id)
                    }
                }
            } header: {
                if !favorites.isEmpty {
                    Text(String(localized: "All Servers"))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .font(Theme.Fonts.caption)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func serverRow(_ server: VLESSConfig) -> some View {
        Button {
            serverStore.setActive(id: server.id)
            dismiss()
        } label: {
            HStack {
                if let flag = server.flagEmoji {
                    Text(flag)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(server.name)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(server.displayAddress)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Ping value
                    if let ping = loadBalancer.formattedPing(for: server) {
                        Text(ping)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(pingColor(for: server))
                    }

                    Text(server.securityLabel)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    if server.id == serverStore.activeServerID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .leading) {
            Button {
                serverStore.toggleFavorite(id: server.id)
            } label: {
                Image(systemName: server.isFavorite ? "star.slash" : "star.fill")
            }
            .tint(Theme.Colors.primary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                serverStore.remove(id: server.id)
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private func pingColor(for server: VLESSConfig) -> Color {
        let ping = loadBalancer.pingFor(server)
        if ping < 100 { return Theme.Colors.success }
        if ping < 300 { return Theme.Colors.primary }
        return Theme.Colors.error
    }
}
