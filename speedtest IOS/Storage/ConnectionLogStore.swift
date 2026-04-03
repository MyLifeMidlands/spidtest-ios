import Foundation

final class ConnectionLogStore: ObservableObject {
    static let shared = ConnectionLogStore()

    @Published private(set) var entries: [ConnectionLogEntry] = []

    private let storageKey = "connection_log"
    private let maxEntries = 100

    private init() {
        load()
    }

    func add(_ entry: ConnectionLogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func log(serverName: String, serverAddress: String, event: ConnectionEvent, duration: TimeInterval? = nil, error: String? = nil) {
        let entry = ConnectionLogEntry(
            serverName: serverName,
            serverAddress: serverAddress,
            event: event,
            duration: duration,
            errorMessage: error
        )
        add(entry)
    }

    func clear() {
        entries = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ConnectionLogEntry].self, from: data) else { return }
        entries = decoded
    }
}
