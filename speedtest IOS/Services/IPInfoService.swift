import Foundation

final class IPInfoService {

    static func fetch() async throws -> IPInfo {
        let url = URL(string: "https://ipwho.is/")!

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IPInfoError.serverError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let ip = json?["ip"] as? String else {
            throw IPInfoError.parseError
        }

        let country = json?["country"] as? String ?? "Unknown"
        let countryCode = json?["country_code"] as? String ?? ""
        let city = json?["city"] as? String ?? ""
        let timezone = json?["timezone"] as? [String: Any]
        let tz = timezone?["id"] as? String ?? ""

        let connection = json?["connection"] as? [String: Any]
        let isp = connection?["isp"] as? String ?? "Unknown"
        let org = connection?["org"] as? String ?? ""

        return IPInfo(
            ip: ip,
            country: country,
            countryCode: countryCode,
            city: city,
            isp: isp,
            org: org,
            timezone: tz
        )
    }
}

enum IPInfoError: LocalizedError {
    case serverError
    case parseError

    var errorDescription: String? {
        switch self {
        case .serverError: return "Failed to fetch IP info"
        case .parseError: return "Failed to parse IP data"
        }
    }
}
