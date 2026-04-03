import Foundation

final class RoutingStore: ObservableObject {
    static let shared = RoutingStore()

    @Published var config: RoutingConfiguration

    private let storageKey = "routing_config"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(RoutingConfiguration.self, from: data) {
            config = decoded
        } else {
            config = RoutingConfiguration()
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func applyPreset(_ preset: RoutingPreset) {
        config.selectedPresetID = preset.id

        // Set mode based on preset
        if preset.id == "max_privacy" {
            config.mode = .allThroughVPN
        } else if preset.id == "ru_direct" {
            config.mode = .allExceptSelected
        } else {
            config.mode = .onlySelected
        }

        // Auto-select matching services
        config.selectedServiceNames.removeAll()
        let presetDomains = Set(preset.domains)
        for service in RoutingService.all {
            let serviceDomains = Set(service.domains)
            if !serviceDomains.isDisjoint(with: presetDomains) {
                config.selectedServiceNames.insert(service.name)
            }
        }

        save()
    }

    func toggleCountry(_ code: String) {
        if config.selectedCountryCodes.contains(code) {
            config.selectedCountryCodes.remove(code)
        } else {
            config.selectedCountryCodes.insert(code)
        }
        save()
    }

    func toggleService(_ name: String) {
        if config.selectedServiceNames.contains(name) {
            config.selectedServiceNames.remove(name)
        } else {
            config.selectedServiceNames.insert(name)
        }
        save()
    }

    func addCustomDomain(_ domain: String) {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !config.customDomains.contains(trimmed) else { return }
        config.customDomains.append(trimmed)
        save()
    }

    func removeCustomDomain(_ domain: String) {
        config.customDomains.removeAll { $0 == domain }
        save()
    }

    func resetAll() {
        config = RoutingConfiguration()
        save()
    }
}
