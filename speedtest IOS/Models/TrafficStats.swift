import Foundation

struct TrafficStats: Codable {
    var sessionDownload: Int64 = 0
    var sessionUpload: Int64 = 0
    var totalDownload: Int64 = 0
    var totalUpload: Int64 = 0

    var sessionTotal: Int64 { sessionDownload + sessionUpload }
    var allTimeTotal: Int64 { totalDownload + totalUpload }

    mutating func resetSession() {
        sessionDownload = 0
        sessionUpload = 0
    }

    mutating func addSession(download: Int64, upload: Int64) {
        sessionDownload += download
        sessionUpload += upload
        totalDownload += download
        totalUpload += upload
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024

        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.0f KB", kb)
        }
        return "\(bytes) B"
    }
}
