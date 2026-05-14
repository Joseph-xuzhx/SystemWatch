import Darwin
import Foundation

actor SystemMonitorService {
    private var previousCPUTicks: [Int32]?
    private var previousProcessCPUTime: [pid_t: UInt64] = [:]
    private var previousProcessSampleDate: Date?

    func fetchSnapshot() async throws -> SystemSnapshot {
        async let processes = fetchProcesses()
        async let cpuPercent = fetchCPUUsedPercent()
        async let memory = fetchMemoryUsage()

        var warnings: [String] = []
        let processList: [RunningProcess]
        let cpuUsage: Double
        let memoryUsage: (usedBytes: Int64, totalBytes: Int64)

        do {
            processList = try await processes
        } catch {
            processList = []
            warnings.append(error.localizedDescription)
        }

        do {
            cpuUsage = try await cpuPercent
        } catch {
            cpuUsage = 0
            warnings.append(error.localizedDescription)
        }

        do {
            memoryUsage = try await memory
        } catch {
            memoryUsage = (0, Int64(ProcessInfo.processInfo.physicalMemory))
            warnings.append(error.localizedDescription)
        }

        let metrics = SystemMetrics(
            cpuUsedPercent: cpuUsage,
            memoryUsedBytes: memoryUsage.usedBytes,
            memoryTotalBytes: memoryUsage.totalBytes,
            processCount: processList.count,
            uptimeSeconds: ProcessInfo.processInfo.systemUptime,
            sampledAt: .now
        )

        return SystemSnapshot(metrics: metrics, processes: processList, warnings: warnings)
    }

    func terminate(pid: Int32, force: Bool) async throws {
        guard pid != ProcessInfo.processInfo.processIdentifier else {
            throw SystemMonitorError.killFailed(pid: pid, message: "SystemWatch cannot end itself.")
        }

        if force {
            try send(signal: SIGKILL, to: pid)
            return
        }

        try send(signal: SIGTERM, to: pid)
        try await Task.sleep(nanoseconds: 900_000_000)

        if processExists(pid: pid) {
            try send(signal: SIGKILL, to: pid)
        }
    }

    private func fetchProcesses() throws -> [RunningProcess] {
        let processes = fetchProcessesWithLibproc()
        if processes.isEmpty {
            throw SystemMonitorError.commandFailed(path: "libproc", message: "No processes were returned by proc_listpids.")
        }
        return processes
    }

    private func fetchProcessesWithLibproc() -> [RunningProcess] {
        let pidBufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard pidBufferSize > 0 else {
            return []
        }

        let pidCount = Int(pidBufferSize) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: pidCount)
        let usedBytes = pids.withUnsafeMutableBufferPointer { buffer in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, buffer.baseAddress, Int32(pidBufferSize))
        }
        let usedCount = Int(usedBytes) / MemoryLayout<pid_t>.size

        let now = Date()
        var nextCPUTime: [pid_t: UInt64] = [:]
        let elapsed = previousProcessSampleDate.map { now.timeIntervalSince($0) } ?? 0
        defer {
            previousProcessCPUTime = nextCPUTime
            previousProcessSampleDate = now
        }

        return pids.prefix(usedCount)
            .filter { $0 > 0 }
            .compactMap { pid in
                processFromLibproc(pid: pid, elapsed: elapsed, nextCPUTime: &nextCPUTime)
            }
            .sorted { lhs, rhs in
                if lhs.cpuPercent == rhs.cpuPercent {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.cpuPercent > rhs.cpuPercent
            }
    }

    private func processFromLibproc(pid: pid_t, elapsed: TimeInterval, nextCPUTime: inout [pid_t: UInt64]) -> RunningProcess? {
        var info = proc_bsdinfo()
        let infoSize = MemoryLayout<proc_bsdinfo>.stride
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: UInt8.self, capacity: infoSize) { reboundPointer in
                proc_pidinfo(pid, Int32(PROC_PIDTBSDINFO), 0, reboundPointer, Int32(infoSize))
            }
        }

        guard result == Int32(infoSize) else {
            return nil
        }

        let command = processPath(pid: pid) ?? string(from: info.pbi_name)
        guard !command.isEmpty else {
            return nil
        }

        let usage = processUsage(pid: pid)
        nextCPUTime[pid] = usage.cpuTimeNanoseconds
        let cpuPercent = processCPUPercent(
            pid: pid,
            cpuTimeNanoseconds: usage.cpuTimeNanoseconds,
            elapsed: elapsed
        )
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let memoryPercent = totalMemory > 0 ? min(100, Double(usage.residentBytes) / totalMemory * 100) : 0
        let appBundleURL = applicationBundleURL(for: command)
        let bundleIdentifier = appBundleURL.flatMap { Bundle(url: $0)?.bundleIdentifier }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let user = userName(for: info.pbi_uid)

        return RunningProcess(
            pid: pid,
            parentPID: Int32(info.pbi_ppid),
            user: user,
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent,
            residentBytes: Int64(usage.residentBytes),
            state: processStateName(Int32(info.pbi_status)),
            command: command,
            applicationPath: appBundleURL?.path,
            bundleIdentifier: bundleIdentifier,
            startDate: startDate(seconds: info.pbi_start_tvsec, microseconds: info.pbi_start_tvusec),
            isApplication: appBundleURL != nil,
            isCurrentProcess: pid == currentPID,
            isCriticalSystemProcess: isCriticalSystemProcess(pid: pid, user: user, command: command)
        )
    }

    private func processPath(pid: pid_t) -> String? {
        var pathBuffer = [CChar](repeating: 0, count: 4096)
        let length = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        guard length > 0 else {
            return nil
        }
        return String(cString: pathBuffer)
    }

    private func userName(for uid: uid_t) -> String {
        guard let password = getpwuid(uid) else {
            return "\(uid)"
        }
        return String(cString: password.pointee.pw_name)
    }

    private func processUsage(pid: pid_t) -> (residentBytes: UInt64, cpuTimeNanoseconds: UInt64) {
        var info = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { reboundPointer in
                proc_pid_rusage(pid, RUSAGE_INFO_V4, reboundPointer)
            }
        }
        guard result == 0 else {
            return (0, 0)
        }
        return (info.ri_resident_size, info.ri_user_time + info.ri_system_time)
    }

    private func processCPUPercent(pid: pid_t, cpuTimeNanoseconds: UInt64, elapsed: TimeInterval) -> Double {
        guard elapsed > 0,
              let previous = previousProcessCPUTime[pid],
              cpuTimeNanoseconds >= previous
        else {
            return 0
        }

        let deltaSeconds = Double(cpuTimeNanoseconds - previous) / 1_000_000_000
        let cpuCount = max(1, ProcessInfo.processInfo.processorCount)
        return min(100, max(0, deltaSeconds / elapsed / Double(cpuCount) * 100))
    }

    private func startDate(seconds: UInt64, microseconds: UInt64) -> Date? {
        guard seconds > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(microseconds) / 1_000_000)
    }

    private func applicationBundleURL(for path: String) -> URL? {
        let url = URL(fileURLWithPath: path)
        let components = url.pathComponents
        guard let appIndex = components.firstIndex(where: { $0.hasSuffix(".app") }) else {
            return nil
        }

        let bundlePath = components.prefix(appIndex + 1).joined(separator: "/")
        guard !bundlePath.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: bundlePath)
    }

    private func isCriticalSystemProcess(pid: pid_t, user: String, command: String) -> Bool {
        if pid <= 1 {
            return true
        }

        let name = URL(fileURLWithPath: command).lastPathComponent
        let criticalNames: Set<String> = [
            "kernel_task",
            "launchd",
            "WindowServer",
            "loginwindow",
            "runningboardd",
            "sysmond",
            "systemstats"
        ]

        return user == "root" && criticalNames.contains(name)
    }

    private func processStateName(_ state: Int32) -> String {
        switch state {
        case 1: "Idle"
        case 2: "Run"
        case 3: "Sleep"
        case 4: "Stop"
        case 5: "Zombie"
        default: "\(state)"
        }
    }

    private func string(from tuple: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)) -> String {
        withUnsafeBytes(of: tuple) { rawBuffer in
            let bytes = rawBuffer.bindMemory(to: CChar.self)
            let characters = Array(bytes.prefix { $0 != 0 })
            return characters.isEmpty ? "" : String(cString: characters + [0])
        }
    }

    private func parseProcessLine(_ line: String) -> RunningProcess? {
        let fields = line.split(maxSplits: 7, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        guard fields.count == 8,
              let pid = Int32(fields[0]),
              let parentPID = Int32(fields[1]),
              let cpuPercent = Double(fields[3]),
              let memoryPercent = Double(fields[4]),
              let residentKilobytes = Int64(fields[5])
        else {
            return nil
        }

        return RunningProcess(
            pid: pid,
            parentPID: parentPID,
            user: String(fields[2]),
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent,
            residentBytes: residentKilobytes * 1024,
            state: String(fields[6]),
            command: String(fields[7]),
            applicationPath: nil,
            bundleIdentifier: nil,
            startDate: nil,
            isApplication: false,
            isCurrentProcess: pid == ProcessInfo.processInfo.processIdentifier,
            isCriticalSystemProcess: false
        )
    }

    private func fetchCPUUsedPercent() throws -> Double {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var cpuCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return 0
        }

        let ticks = Array(UnsafeBufferPointer(start: cpuInfo, count: Int(cpuInfoCount)))
        vm_deallocate(
            mach_task_self_,
            vm_address_t(UInt(bitPattern: cpuInfo)),
            vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride)
        )

        guard let previousCPUTicks, previousCPUTicks.count == ticks.count else {
            previousCPUTicks = ticks
            return 0
        }

        self.previousCPUTicks = ticks

        var usedTicks: Int64 = 0
        var totalTicks: Int64 = 0
        let stride = Int(CPU_STATE_MAX)

        for cpuIndex in 0..<Int(cpuCount) {
            let base = cpuIndex * stride
            let user = Int64(ticks[base + Int(CPU_STATE_USER)] - previousCPUTicks[base + Int(CPU_STATE_USER)])
            let system = Int64(ticks[base + Int(CPU_STATE_SYSTEM)] - previousCPUTicks[base + Int(CPU_STATE_SYSTEM)])
            let nice = Int64(ticks[base + Int(CPU_STATE_NICE)] - previousCPUTicks[base + Int(CPU_STATE_NICE)])
            let idle = Int64(ticks[base + Int(CPU_STATE_IDLE)] - previousCPUTicks[base + Int(CPU_STATE_IDLE)])

            usedTicks += max(0, user + system + nice)
            totalTicks += max(0, user + system + nice + idle)
        }

        guard totalTicks > 0 else {
            return 0
        }

        return min(100, max(0, Double(usedTicks) / Double(totalTicks) * 100))
    }

    private func fetchMemoryUsage() throws -> (usedBytes: Int64, totalBytes: Int64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, Int64(ProcessInfo.processInfo.physicalMemory))
        }

        let pageSize = Int64(vm_kernel_page_size)
        let active = Int64(stats.active_count)
        let wired = Int64(stats.wire_count)
        let compressed = Int64(stats.compressor_page_count)
        let speculative = Int64(stats.speculative_count)
        let usedPages = max(0, active + wired + compressed - speculative)
        return (usedPages * pageSize, Int64(ProcessInfo.processInfo.physicalMemory))
    }

    private func runCommand(path: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw SystemMonitorError.commandFailed(path: path, message: error.localizedDescription)
        }
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw SystemMonitorError.commandFailed(path: path, message: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }

    private func send(signal: Int32, to pid: Int32) throws {
        if Darwin.kill(pid, signal) != 0 {
            let code = errno
            throw SystemMonitorError.killFailed(pid: pid, message: String(cString: strerror(code)))
        }
    }

    private func processExists(pid: Int32) -> Bool {
        if Darwin.kill(pid, 0) == 0 {
            return true
        }

        return errno == EPERM
    }
}

enum SystemMonitorError: LocalizedError {
    case commandFailed(path: String, message: String)
    case killFailed(pid: Int32, message: String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let path, let message):
            return "\(path) failed: \(message)"
        case .killFailed(let pid, let message):
            return "Unable to end process \(pid): \(message)"
        }
    }
}
