import Foundation
import Combine

final class TrafficStatsStore: ObservableObject {
    static let shared = TrafficStatsStore()

    @Published var stats: TrafficStats

    private let storageKey = "traffic_stats"
    private var pollTimer: Timer?

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(TrafficStats.self, from: data) {
            stats = decoded
        } else {
            stats = TrafficStats()
        }
    }

    func startSession() {
        stats.resetSession()
        startPolling()
    }

    func endSession() {
        stopPolling()
        save()
    }

    func updateTraffic(download: Int64, upload: Int64) {
        stats.sessionDownload = download
        stats.sessionUpload = upload
        save()
    }

    func addTrafficSample(download: Int64, upload: Int64) {
        stats.addSession(download: download, upload: upload)
        save()
    }

    func resetAll() {
        stats = TrafficStats()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // Poll network interface stats
    private func startPolling() {
        stopPolling()
        var lastDown: Int64 = Self.getInterfaceBytes(direction: .download)
        var lastUp: Int64 = Self.getInterfaceBytes(direction: .upload)

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            let currentDown = Self.getInterfaceBytes(direction: .download)
            let currentUp = Self.getInterfaceBytes(direction: .upload)

            let deltaDown = max(0, currentDown - lastDown)
            let deltaUp = max(0, currentUp - lastUp)

            lastDown = currentDown
            lastUp = currentUp

            if deltaDown > 0 || deltaUp > 0 {
                DispatchQueue.main.async {
                    self.stats.addSession(download: deltaDown, upload: deltaUp)
                    self.save()
                }
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    enum Direction {
        case download, upload
    }

    static func getInterfaceBytes(direction: Direction) -> Int64 {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return 0 }

        var totalBytes: Int64 = 0

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)

            // Only count en0 (WiFi) and pdp_ip0 (cellular)
            if name == "en0" || name == "pdp_ip0" {
                if let data = current.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    switch direction {
                    case .download:
                        totalBytes += Int64(networkData.pointee.ifi_ibytes)
                    case .upload:
                        totalBytes += Int64(networkData.pointee.ifi_obytes)
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        freeifaddrs(ifaddr)
        return totalBytes
    }
}
