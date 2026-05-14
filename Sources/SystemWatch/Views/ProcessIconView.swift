import AppKit
import SwiftUI

struct ProcessIconView: View {
    let process: RunningProcess

    var body: some View {
        Group {
            if let image = icon {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: process.isApplication ? "app" : "gearshape")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 18, height: 18)
    }

    private var icon: NSImage? {
        guard process.isApplication || !process.command.isEmpty else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: process.applicationPath ?? process.command)
    }
}
