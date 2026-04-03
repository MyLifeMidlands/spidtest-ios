import Foundation

final class WebRTCLeakService {

    struct WebRTCResult {
        let localIPs: [String]
        let hasLeak: Bool
    }

    /// Check for WebRTC leaks by fetching external IP and comparing
    /// with the VPN IP. If they differ, there's a potential leak.
    static func checkLeak(vpnIP: String?) async -> WebRTCResult {
        // Get local network interfaces to detect local IPs
        let localIPs = getLocalIPAddresses()

        // Filter out loopback and link-local addresses
        let relevantIPs = localIPs.filter { ip in
            !ip.hasPrefix("127.") &&
            !ip.hasPrefix("::1") &&
            !ip.hasPrefix("fe80") &&
            !ip.hasPrefix("10.") && // VPN tunnel IPs
            !ip.hasPrefix("169.254")
        }

        // If we have a VPN IP and find non-VPN public-like IPs, it's a potential leak
        if let vpnIP = vpnIP {
            let hasLeak = relevantIPs.contains { ip in
                ip != vpnIP && isPublicIP(ip)
            }
            return WebRTCResult(localIPs: relevantIPs, hasLeak: hasLeak)
        }

        return WebRTCResult(localIPs: relevantIPs, hasLeak: false)
    }

    /// Get all local IP addresses from network interfaces
    private static func getLocalIPAddresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return addresses
        }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)

            if (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING) {
                var addr = current.pointee.ifa_addr.pointee

                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(&addr, socklen_t(addr.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let address = String(cString: hostname)
                        let ifname = String(cString: current.pointee.ifa_name!)

                        // Include WiFi (en0) and cellular (pdp_ip0) interfaces
                        if ifname == "en0" || ifname.hasPrefix("pdp_ip") {
                            addresses.append(address)
                        }
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        freeifaddrs(ifaddr)
        return addresses
    }

    private static func isPublicIP(_ ip: String) -> Bool {
        // Simple check: if it's not a private IP range, consider it public
        let privateRanges = ["10.", "172.16.", "172.17.", "172.18.", "172.19.",
                            "172.20.", "172.21.", "172.22.", "172.23.", "172.24.",
                            "172.25.", "172.26.", "172.27.", "172.28.", "172.29.",
                            "172.30.", "172.31.", "192.168.", "127.", "169.254."]
        return !privateRanges.contains(where: { ip.hasPrefix($0) })
    }
}
