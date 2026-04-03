import Foundation

struct IPInfo: Codable {
    let ip: String
    let country: String
    let countryCode: String
    let city: String
    let isp: String
    let org: String
    let timezone: String

    var flagEmoji: String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }

    var location: String {
        if city.isEmpty { return country }
        return "\(city), \(country)"
    }
}
