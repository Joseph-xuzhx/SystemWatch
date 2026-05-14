import Foundation

enum ProcessSort: String, CaseIterable, Identifiable {
    case cpu
    case memory
    case name
    case pid
    case user

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .cpu: L10n.text(.cpu, language)
        case .memory: L10n.text(.memory, language)
        case .name: L10n.text(.name, language)
        case .pid: L10n.text(.pid, language)
        case .user: L10n.text(.user, language)
        }
    }
}

enum ProcessFilter: String, CaseIterable, Identifiable {
    case all
    case currentUser
    case applications
    case background

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all: L10n.text(.allProcesses, language)
        case .currentUser: L10n.text(.currentUserOnly, language)
        case .applications: L10n.text(.applicationsOnly, language)
        case .background: L10n.text(.backgroundOnly, language)
        }
    }
}

enum RefreshInterval: String, CaseIterable, Identifiable {
    case oneSecond
    case threeSeconds
    case fiveSeconds
    case paused

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .oneSecond: 1
        case .threeSeconds: 3
        case .fiveSeconds: 5
        case .paused: nil
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .oneSecond: L10n.text(.oneSecond, language)
        case .threeSeconds: L10n.text(.threeSeconds, language)
        case .fiveSeconds: L10n.text(.fiveSeconds, language)
        case .paused: L10n.text(.paused, language)
        }
    }
}

struct MetricSample: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let cpuPercent: Double
    let memoryPercent: Double
}
