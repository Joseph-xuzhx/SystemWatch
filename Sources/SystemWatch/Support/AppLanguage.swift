import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese: "中文"
        case .english: "English"
        }
    }
}

enum L10n {
    static func text(_ key: Key, _ language: AppLanguage) -> String {
        switch language {
        case .chinese:
            chinese[key] ?? english[key] ?? key.rawValue
        case .english:
            english[key] ?? key.rawValue
        }
    }

    enum Key: String {
        case appName
        case overview
        case processes
        case refresh
        case language
        case cpu
        case memory
        case processCount
        case uptime
        case updated
        case sinceLastBoot
        case topCPUProcesses
        case name
        case pid
        case user
        case state
        case command
        case end
        case endProcess
        case endProcesses
        case endSelectedProcess
        case forceQuit
        case more
        case moreProcessActions
        case cancel
        case noProcesses
        case noMatches
        case noProcessesDescription
        case noMatchesDescription
        case searchPrompt
        case protectedProcessWarning
        case waitingFirstRefresh
        case lastRefresh
        case refreshFailed
        case status
        case zeroProcessSnapshot
        case sortBy
        case filter
        case allProcesses
        case currentUserOnly
        case applicationsOnly
        case backgroundOnly
        case refreshRate
        case oneSecond
        case threeSeconds
        case fiveSeconds
        case paused
        case details
        case parentPID
        case path
        case bundleID
        case started
        case kind
        case application
        case backgroundProcess
        case selectedProcess
        case noSelection
        case noSelectionDescription
        case protected
        case currentApp
        case memoryHistory
        case cpuHistory
        case showMainWindow
        case quit
        case menuBarStatus
        case idle
        case running
        case sleeping
        case stopped
        case zombie
        case unknown
    }

    private static let english: [Key: String] = [
        .appName: "SystemWatch",
        .overview: "Overview",
        .processes: "Processes",
        .refresh: "Refresh",
        .language: "Language",
        .cpu: "CPU",
        .memory: "Memory",
        .processCount: "Processes",
        .uptime: "Uptime",
        .updated: "Updated",
        .sinceLastBoot: "Since last boot",
        .topCPUProcesses: "Top CPU Processes",
        .name: "Name",
        .pid: "PID",
        .user: "User",
        .state: "State",
        .command: "Command",
        .end: "End",
        .endProcess: "End Process",
        .endProcesses: "End %d Processes",
        .endSelectedProcess: "End selected process",
        .forceQuit: "Force Quit",
        .more: "More",
        .moreProcessActions: "More process actions",
        .cancel: "Cancel",
        .noProcesses: "No Processes",
        .noMatches: "No Matches",
        .noProcessesDescription: "SystemWatch could not read the process list.",
        .noMatchesDescription: "Try a different search.",
        .searchPrompt: "Search process, PID, user, or command",
        .protectedProcessWarning: "macOS may refuse requests for protected or other-user processes.",
        .waitingFirstRefresh: "Waiting for first refresh...",
        .lastRefresh: "Last refresh: %d processes, CPU %@, memory %@ at %@",
        .refreshFailed: "Refresh failed: %@",
        .status: "Status: %@",
        .zeroProcessSnapshot: "Process snapshot returned 0 items. Run --diagnose-snapshot to compare the service path from Terminal.",
        .sortBy: "Sort",
        .filter: "Filter",
        .allProcesses: "All Processes",
        .currentUserOnly: "Current User",
        .applicationsOnly: "Applications",
        .backgroundOnly: "Background",
        .refreshRate: "Refresh Rate",
        .oneSecond: "1 second",
        .threeSeconds: "3 seconds",
        .fiveSeconds: "5 seconds",
        .paused: "Paused",
        .details: "Details",
        .parentPID: "Parent PID",
        .path: "Path",
        .bundleID: "Bundle ID",
        .started: "Started",
        .kind: "Kind",
        .application: "Application",
        .backgroundProcess: "Background Process",
        .selectedProcess: "Selected Process",
        .noSelection: "No Selection",
        .noSelectionDescription: "Select a process to inspect details.",
        .protected: "Protected",
        .currentApp: "Current App",
        .memoryHistory: "Memory History",
        .cpuHistory: "CPU History",
        .showMainWindow: "Show Main Window",
        .quit: "Quit",
        .menuBarStatus: "System Status",
        .idle: "Idle",
        .running: "Running",
        .sleeping: "Sleeping",
        .stopped: "Stopped",
        .zombie: "Zombie",
        .unknown: "Unknown"
    ]

    private static let chinese: [Key: String] = [
        .appName: "SystemWatch",
        .overview: "概览",
        .processes: "进程",
        .refresh: "刷新",
        .language: "语言",
        .cpu: "CPU",
        .memory: "内存",
        .processCount: "进程数",
        .uptime: "运行时间",
        .updated: "更新于",
        .sinceLastBoot: "自上次启动以来",
        .topCPUProcesses: "CPU 占用最高的进程",
        .name: "名称",
        .pid: "PID",
        .user: "用户",
        .state: "状态",
        .command: "命令",
        .end: "结束",
        .endProcess: "结束进程",
        .endProcesses: "结束 %d 个进程",
        .endSelectedProcess: "结束选中的进程",
        .forceQuit: "强制结束",
        .more: "更多",
        .moreProcessActions: "更多进程操作",
        .cancel: "取消",
        .noProcesses: "没有进程",
        .noMatches: "没有匹配项",
        .noProcessesDescription: "SystemWatch 无法读取进程列表。",
        .noMatchesDescription: "请尝试其他搜索条件。",
        .searchPrompt: "搜索进程、PID、用户或命令",
        .protectedProcessWarning: "macOS 可能会拒绝结束受保护或其他用户的进程。",
        .waitingFirstRefresh: "正在等待首次刷新...",
        .lastRefresh: "上次刷新：%d 个进程，CPU %@，内存 %@，时间 %@",
        .refreshFailed: "刷新失败：%@",
        .status: "状态：%@",
        .zeroProcessSnapshot: "进程快照返回 0 项。请运行 --diagnose-snapshot 对比终端中的服务路径。",
        .sortBy: "排序",
        .filter: "筛选",
        .allProcesses: "全部进程",
        .currentUserOnly: "当前用户",
        .applicationsOnly: "应用程序",
        .backgroundOnly: "后台进程",
        .refreshRate: "刷新频率",
        .oneSecond: "1 秒",
        .threeSeconds: "3 秒",
        .fiveSeconds: "5 秒",
        .paused: "暂停",
        .details: "详情",
        .parentPID: "父进程 PID",
        .path: "路径",
        .bundleID: "Bundle ID",
        .started: "启动时间",
        .kind: "类型",
        .application: "应用程序",
        .backgroundProcess: "后台进程",
        .selectedProcess: "选中进程",
        .noSelection: "未选择进程",
        .noSelectionDescription: "选择一个进程查看详情。",
        .protected: "受保护",
        .currentApp: "当前应用",
        .memoryHistory: "内存历史",
        .cpuHistory: "CPU 历史",
        .showMainWindow: "显示主窗口",
        .quit: "退出",
        .menuBarStatus: "系统状态",
        .idle: "空闲",
        .running: "运行",
        .sleeping: "休眠",
        .stopped: "停止",
        .zombie: "僵尸进程",
        .unknown: "未知"
    ]
}
