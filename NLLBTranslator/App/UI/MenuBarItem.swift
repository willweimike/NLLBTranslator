import Cocoa
import Combine
import KeyboardShortcuts
import SwiftUI

class MenubarItem: NSObject {
    let nllbtranslator: NLLBTranslator
    let preferences = Preferences.shared
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let statusBarmenu = NSMenu()
    let captureTextItem = NSMenuItem(title: "Capture Text", action: #selector(captureScreen), keyEquivalent: "")
    let ignoreLineBreaksItem = NSMenuItem(title: "Ignore Line Breaks", action: #selector(ignoreLineBreaks), keyEquivalent: "")
    let preferencesItem = NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ",")
    let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")

    var cancellable: AnyCancellable?
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()

    init(_ nllbtranslator: NLLBTranslator) {
        self.nllbtranslator = nllbtranslator
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.menu = statusBarmenu
        super.init()
        buildMenu()

        statusBarItem.button?.window?.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        statusBarItem.button?.window?.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        statusBarItem.button?.window?.delegate = self

        cancellable = preferences.$menuBarIcon.sink { [weak self] item in
            let size: CGFloat = (item == .Option1) ? 18 : 20
            let image = item.nsImage().resizedCopy(w: size, h: size)
            image.isTemplate = true
            self?.statusBarItem.button?.image = image
        }
    }

    private func buildMenu() {
        [captureTextItem, ignoreLineBreaksItem, quitItem].forEach { $0.target = self }
        statusBarmenu.addItem(captureTextItem)
        statusBarmenu.addItem(ignoreLineBreaksItem)
        statusBarmenu.addItem(NSMenuItem.separator())
        // Removed the fragile manipulation of main menu items.
        statusBarmenu.addItem(quitItem)
        statusBarmenu.delegate = self
    }

    @objc func captureScreen() {
        nllbtranslator.capture(.captureScreen)
    }

    @objc func ignoreLineBreaks() {
        preferences.ignoreLineBreaks.toggle()
    }

    @objc func quitApp() {
        NSApp.terminate(self)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel()
    }

    // FIX: Use the SwiftUI Settings scene instead of creating an unmanaged window.
    @objc func showPreferences() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension MenubarItem: NSMenuDelegate {
    func menuWillOpen(_: NSMenu) {
        captureTextItem.setShortcut(for: .captureScreen)
        ignoreLineBreaksItem.state = preferences.ignoreLineBreaks ? .on:.off
    }
}

extension MenubarItem: NSWindowDelegate, NSDraggingDestination {
    func draggingEntered(_: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var files: [String] = []
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self,
        ]

        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: ["public.image"],
        ]

        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)

        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, _ in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: destinationURL, options: [:], operationQueue: self.workQueue) { fileURL, error in
                    if error == nil {
                        files.append(fileURL.path)
                    }
                }
            case let fileURL as URL:
                files.append(fileURL.path)
            default: break
            }
        }
        return true
    }
}
