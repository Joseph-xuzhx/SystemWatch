import AppKit
import SwiftUI

struct RightClickSelectionView: NSViewRepresentable {
    let select: () -> Void
    let endTitle: String
    let forceQuitTitle: String
    let canTerminate: Bool
    let end: () -> Void
    let forceQuit: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RightClickView()
        view.select = select
        view.menuProvider = { context.coordinator.makeMenu() }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        if let view = nsView as? RightClickView {
            view.select = select
            view.menuProvider = { context.coordinator.makeMenu() }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject {
        var parent: RightClickSelectionView

        init(parent: RightClickSelectionView) {
            self.parent = parent
        }

        func makeMenu() -> NSMenu {
            let menu = NSMenu()
            let endItem = NSMenuItem(title: parent.endTitle, action: #selector(endProcess), keyEquivalent: "")
            endItem.target = self
            endItem.isEnabled = parent.canTerminate
            menu.addItem(endItem)

            let forceItem = NSMenuItem(title: parent.forceQuitTitle, action: #selector(forceQuitProcess), keyEquivalent: "")
            forceItem.target = self
            forceItem.isEnabled = parent.canTerminate
            menu.addItem(forceItem)
            return menu
        }

        @objc private func endProcess() {
            parent.end()
        }

        @objc private func forceQuitProcess() {
            parent.forceQuit()
        }
    }

    private final class RightClickView: NSView {
        var select: (() -> Void)?
        var menuProvider: (() -> NSMenu)?

        override var acceptsFirstResponder: Bool { false }

        override func hitTest(_ point: NSPoint) -> NSView? {
            self
        }

        override func rightMouseDown(with event: NSEvent) {
            select?()
            guard let menu = menuProvider?() else {
                return
            }
            let point = convert(event.locationInWindow, from: nil)
            menu.popUp(positioning: nil, at: point, in: self)
        }

        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                select?()
            }
            super.mouseDown(with: event)
        }
    }
}
