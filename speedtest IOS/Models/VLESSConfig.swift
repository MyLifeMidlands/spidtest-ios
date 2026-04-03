import Foundation

struct VLESSConfig: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var port: Int
    var uuid: String

    // Protocol
    var encryption: String
    var flow: String?

    // Security
    var security: String  // "tls" / "reality" / "none"
    var sni: String?
    var fingerprint: String?
    var alpn: [String]?

    // Reality
    var publicKey: String?
    var shortId: String?
    var spiderX: String?

    // Transport
    var network: String  // "tcp" / "ws" / "grpc" / "h2"
    var wsPath: String?
    var wsHost: String?
    var grpcServiceName: String?

    // Geo
    var countryCode: String?

    // Favorites
    var isFavorite: Bool

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        port: Int,
        uuid: String,
        encryption: String = "none",
        flow: String? = nil,
        security: String = "tls",
        sni: String? = nil,
        fingerprint: String? = nil,
        alpn: [String]? = nil,
        publicKey: String? = nil,
        shortId: String? = nil,
        spiderX: String? = nil,
        network: String = "tcp",
        wsPath: String? = nil,
        wsHost: String? = nil,
        grpcServiceName: String? = nil,
        countryCode: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
        self.uuid = uuid
        self.encryption = encryption
        self.flow = flow
        self.security = security
        self.sni = sni
        self.fingerprint = fingerprint
        self.alpn = alpn
        self.publicKey = publicKey
        self.shortId = shortId
        self.spiderX = spiderX
        self.network = network
        self.wsPath = wsPath
        self.wsHost = wsHost
        self.grpcServiceName = grpcServiceName
        self.countryCode = countryCode
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    // Support decoding old configs without isFavorite
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        port = try container.decode(Int.self, forKey: .port)
        uuid = try container.decode(String.self, forKey: .uuid)
        encryption = try container.decode(String.self, forKey: .encryption)
        flow = try container.decodeIfPresent(String.self, forKey: .flow)
        security = try container.decode(String.self, forKey: .security)
        sni = try container.decodeIfPresent(String.self, forKey: .sni)
        fingerprint = try container.decodeIfPresent(String.self, forKey: .fingerprint)
        alpn = try container.decodeIfPresent([String].self, forKey: .alpn)
        publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey)
        shortId = try container.decodeIfPresent(String.self, forKey: .shortId)
        spiderX = try container.decodeIfPresent(String.self, forKey: .spiderX)
        network = try container.decode(String.self, forKey: .network)
        wsPath = try container.decodeIfPresent(String.self, forKey: .wsPath)
        wsHost = try container.decodeIfPresent(String.self, forKey: .wsHost)
        grpcServiceName = try container.decodeIfPresent(String.self, forKey: .grpcServiceName)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    var displayAddress: String {
        address
    }

    var securityLabel: String {
        switch security {
        case "reality": return "Reality"
        case "tls": return "TLS"
        default: return "None"
        }
    }

    var flagEmoji: String? {
        guard let code = countryCode, code.count == 2 else { return nil }
        let base: UInt32 = 0x1F1E6
        let aValue = UInt32(UnicodeScalar("A").value)
        let chars = code.uppercased().unicodeScalars.compactMap { scalar -> Character? in
            guard let s = UnicodeScalar(base + scalar.value - aValue) else { return nil }
            return Character(s)
        }
        return chars.count == 2 ? String(chars) : nil
    }

    var networkLabel: String {
        switch network {
        case "ws": return "WebSocket"
        case "grpc": return "gRPC"
        case "h2": return "HTTP/2"
        default: return "TCP"
        }
    }
}
