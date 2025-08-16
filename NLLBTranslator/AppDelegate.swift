import Combine
import KeyboardShortcuts
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarItem: MenubarItem?
    var nllbtranslator = NLLBTranslator()
    let preferences = Preferences.shared
    var cancellable: Set<AnyCancellable> = []
    
    func applicationDidFinishLaunching(_: Notification) {
        let bundleID = Bundle.main.bundleIdentifier!
        
        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            NSWorkspace.shared.open(URL(string: "nllbtranslator://showPreferences")!)
            NSApp.terminate(nil)
        }
        
        preferences.$showMenuBarIcon.sink(receiveValue: { [weak self] show in
            guard let self = self else { return }
            if show {
                self.menuBarItem = MenubarItem(self.nllbtranslator)
                return
            }
            self.menuBarItem = nil
        }).store(in: &cancellable)
        
        setupShortcuts()
        
    }
    
    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            switch url.host?.lowercased() {
            case "capture":
                nllbtranslator.capture(.captureScreen)
            case "showpreferences":
                if let menu = NSApp.mainMenu?.items.first?.submenu {
                    menu.performActionForItem(at: 0)
                }
            default:
                return
            }
        }
    }
    
    func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .captureScreen) { [self] in
            nllbtranslator.capture(.captureScreen)
        }
    }
    
}
