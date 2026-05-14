import Foundation

enum MonitorSection: String, CaseIterable, Identifiable {
    case overview
    case processes

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .overview: L10n.text(.overview, language)
        case .processes: L10n.text(.processes, language)
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "gauge.with.dots.needle.67percent"
        case .processes: "list.bullet.rectangle"
        }
    }
}
