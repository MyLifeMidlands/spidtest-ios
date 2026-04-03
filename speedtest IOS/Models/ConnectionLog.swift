import Foundation

struct ConnectionLogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let serverName: String
    let serverAddress: String
    let event: ConnectionEvent
    let duration: TimeInterval?
    let errorMessage: String?

    init(
        serverName: String,
        serverAddress: String,
        event: ConnectionEvent,
        duration: TimeInterval? = nil,
        errorMessage: String? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.serverName = serverName
        self.serverAddress = serverAddress
        self.event = event
        self.duration = duration
        self.errorMessage = errorMessage
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    var formattedDuration: String? {
        guard let duration = duration, duration > 0 else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        }
        return String(format: "%dm %02ds", minutes, seconds)
    }
}

enum ConnectionEvent: String, Codable {
    case connected
    case disconnected
    case error
    case reconnected
    case failover

    var label: String {
        switch self {
        case .connected: return String(localized: "Connected")
        case .disconnected: return String(localized: "Disconnected")
        case .error: return String(localized: "Error")
        case .reconnected: return String(localized: "Reconnected")
        case .failover: return String(localized: "Failover")
        }
    }

    var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .reconnected: return "arrow.counterclockwise"
        case .failover: return "arrow.triangle.branch"
        }
    }

    var color: String {
        switch self {
        case .connected, .reconnected: return "success"
        case .disconnected: return "textSecondary"
        case .error: return "error"
        case .failover: return "primary"
        }
    }
}
