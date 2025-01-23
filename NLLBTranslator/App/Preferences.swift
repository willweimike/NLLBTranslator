import Cocoa
import Combine
import SwiftUI

class Preferences: ObservableObject {
    static let shared = Preferences()
    enum PreferencesKeys: String {
        case CaptureSound
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
        case French = "French"
        case Italian = "Italian"
        case German = "German"
        case Spanish = "Spanish"
        case Portuguese = "Portuguese"
        case Chinese = "Chinese"

        func languageCode() -> String {
            switch self {
            case .English:
                return "en_US"
            case .French:
                return "fr"
            case .Italian:
                return "it"
            case .German:
                return "de"
            case .Spanish:
                return "es"
            case .Portuguese:
                return "pt"
            case .Chinese:
                return "zh"
            }
        }
    }
    
    enum TranslationLanguage: String, CaseIterable {
        case English = "English"
        case ChineseSimplified = "Chinese Simplified"
        case ChineseTraditional = "Chinese Traditional"
        case Estonian = "Estonian"
        case Finnish = "Finnish"
        case French = "French"
        case Hindi = "Hindi"
        case Romanian = "Romanian"
        case Latvian = "Latvian"
        case Russian = "Russian"
        case Spanish = "Spanish"
        case Turkish = "Turkish"
        case Kinyarwanda = "Kinyarwanda"
        
        func languageCode() -> String {
            switch self {
            case .English: return "eng_Latn"
            case .ChineseSimplified: return "zho_Hans"
            case .ChineseTraditional: return "zho_Hant"
            case .Estonian: return "est_Latn"
            case .Finnish: return "fin_Latn"
            case .French: return "fra_Latn"
            case .Hindi: return "hin_Deva"
            case .Romanian: return "ron_Latn"
            case .Latvian: return "lvs_Latn"
            case .Russian: return "rus_Cyrl"
            case .Spanish: return "spa_Latn"
            case .Turkish: return "tur_Latn"
            case .Kinyarwanda: return "kin_Latn"
            }
        }
    }

    @Published var captureSound: Bool {
        didSet {
            Preferences.setValue(value: captureSound, key: .CaptureSound)
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
        captureSound = Preferences.getValue(key: .CaptureSound) as? Bool ?? true
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
