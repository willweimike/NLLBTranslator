import Cocoa
import Combine
import SwiftUI

class Preferences: ObservableObject {
    static let shared = Preferences()
    enum PreferencesKeys: String {
        case ResultNotification
        case ShowMenuBarIcon
        case IgnoreLineBreaks
        case RecongitionLanguage
        case MenuBarIcon
        case TranslationTargetLanguage
    }

    enum MenuBarIcon: String, CaseIterable {
        case Option1
        case Option2

        func image() -> Image {
            Image(nsImage: nsImage())
        }

        func nsImage() -> NSImage {
            var image: NSImage?
            let imageConfig = NSImage.SymbolConfiguration(pointSize: 50, weight: .heavy, scale: .large)
            switch self {
            case .Option1:
                image = NSImage(systemSymbolName: "perspective", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            case .Option2:
                image = NSImage(systemSymbolName: "crop", accessibilityDescription: nil)?.withSymbolConfiguration(imageConfig)
            }
            image?.isTemplate = true
            return image!
        }
    }

    enum RecongitionLanguage: String, CaseIterable {
        case English = "English"
        case ChineseSimplified = "Chinese Simplified"
        case ChineseTraditional = "Chinese Traditional"
        case French = "French"
        case Korean = "Korean"
        case Japanese = "Japanese"
        case Italian = "Italian"
        case German = "German"

        func languageCode() -> String {
            switch self {
            case .English:
                return "en-US"
            case .French:
                return "fr-FR"
            case .Korean:
                return "ko-KR"
            case .Italian:
                return "it-IT"
            case .ChineseTraditional:
                return "zh-Hant"
            case .ChineseSimplified:
                return "zh-Hans"
            case .Japanese:
                return "ja-JP"
            case .German:
                return "de-DE"
            }
        }
    }
        
    enum TranslationLanguage: String, CaseIterable {
        case English = "English"
        case ChineseSimplified = "Chinese Simplified"
        case ChineseTraditional = "Chinese Traditional"
        case French = "French"
        case Korean = "Korean"
        case Japanese = "Japanese"
        case Italian = "Italian"
        case German = "German"
        
        
        func languageCode() -> String {
            switch self {
            case .English: return "eng_Latn"
            case .ChineseSimplified: return "zho_Hans"
            case .ChineseTraditional: return "zho_Hant"
            case .Korean: return "kor_Hang"
            case .Japanese: return "jpn_Jpan"
            case .French: return "fra_Latn"
            case .German: return "deu_Latn"
            case .Italian: return "ita_Latn"
            }
        }
    }

    
    @Published var resultNotification: Bool {
        didSet {
            Preferences.setValue(value: resultNotification, key: .ResultNotification)
        }
    }

    @Published var showMenuBarIcon: Bool {
        didSet {
            Preferences.setValue(value: showMenuBarIcon, key: .ShowMenuBarIcon)
        }
    }
    
    @Published var ignoreLineBreaks: Bool {
        didSet {
            Preferences.setValue(value: ignoreLineBreaks, key: .IgnoreLineBreaks)
        }
    }

    @Published var recongitionLanguage: RecongitionLanguage {
        didSet {
            Preferences.setValue(value: recongitionLanguage.rawValue, key: .RecongitionLanguage)
        }
    }

    @Published var menuBarIcon: MenuBarIcon {
        didSet {
            Preferences.setValue(value: menuBarIcon.rawValue, key: .MenuBarIcon)
        }
    }
    
    @Published var translationTargetLanguage: TranslationLanguage {
        didSet {
            Preferences.setValue(value: translationTargetLanguage.rawValue, key: .TranslationTargetLanguage)
        }
    }

    init() {
        resultNotification = Preferences.getValue(key: .ResultNotification) as? Bool ?? false
        showMenuBarIcon = Preferences.getValue(key: .ShowMenuBarIcon) as? Bool ?? true
        ignoreLineBreaks = Preferences.getValue(key: .IgnoreLineBreaks) as? Bool ?? true

        recongitionLanguage = .English
        if let lang = Preferences.getValue(key: .RecongitionLanguage) as? String {
            recongitionLanguage = RecongitionLanguage(rawValue: lang) ?? .English
        }
        menuBarIcon = .Option1
        if let mbitem = Preferences.getValue(key: .MenuBarIcon) as? String {
            menuBarIcon = MenuBarIcon(rawValue: mbitem) ?? .Option1
        }
        translationTargetLanguage = .English
        if let lang = Preferences.getValue(key: .TranslationTargetLanguage) as? String {
            translationTargetLanguage = TranslationLanguage(rawValue: lang) ?? .English
        }
    }

    static func removeAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    private static func setValue(value: Any?, key: PreferencesKeys) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    private static func getValue(key: PreferencesKeys) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
}
