import SwiftUI

struct ConnectionLogView: View {
    @ObservedObject private var store = ConnectionLogStore.shared

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            if store.entries.isEmpty {
                emptyState
            } else {
                logList
            }
        }
        .navigationTitle(String(localized: "Connection Log"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Clear")) {
                        store.clear()
                    }
                    .foregroundStyle(Theme.Colors.error)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(String(localized: "No connection history"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(String(localized: "Connection events will appear here"))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
    }

    private var logList: some View {
        List {
            ForEach(store.entries) { entry in
                logRow(entry)
                    .listRowBackground(Theme.Colors.surface)
                    .listRowSeparatorTint(Theme.Colors.surfaceLight)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func logRow(_ entry: ConnectionLogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.event.icon)
                .foregroundStyle(colorForEvent(entry.event))
                .font(.system(size: 18))
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.event.label)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text(entry.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Text(entry.serverName)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let duration = entry.formattedDuration {
                    Text(String(localized: "Duration: \(duration)"))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.primary)
                }

                if let error = entry.errorMessage {
                    Text(error)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.error)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForEvent(_ event: ConnectionEvent) -> Color {
        switch event {
        case .connected, .reconnected: return Theme.Colors.success
        case .disconnected: return Theme.Colors.textSecondary
        case .error: return Theme.Colors.error
        case .failover: return Theme.Colors.primary
        }
    }
}
