import SwiftUI
import Vision
import UserNotifications

class NLLBTranslator: NSObject {
    public static let shared = NLLBTranslator()
    let preferences = Preferences.shared
    private var currentInvocationMode: InvocationMode = .captureScreen
    
    var task: Process?
    let sceenCaptureURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    
    lazy var screenShotFilePath: String = {
        let directory = NSTemporaryDirectory()
        return NSURL.fileURL(withPathComponents: [directory, "capture.png"])!.path
    }()
    
    var screenCaptureArguments: [String] {
        var out = ["-i"] // capture screen interactively, by selection or window
        out.append(screenShotFilePath)
        return out
    }
    
    func capture(_ mode: InvocationMode) {
        currentInvocationMode = mode
        _capture() { [weak self] text in
            guard let text = text else { return }
            self?.precessDetectedText(text)
        }
    }
    
    private func getImage() -> NSImage? {
        switch currentInvocationMode {
        case .captureScreen:
            task = Process()
            task?.executableURL = sceenCaptureURL
            
            task?.arguments = screenCaptureArguments
            
            do {
                try task?.run()
            } catch {
                print("Failed to capture")
                task = nil
                return nil
            }
            
            task?.waitUntilExit()
            task = nil
            return NSImage(contentsOfFile: screenShotFilePath)
        }
    }
    
    private func _capture(completionHandler: (String?) -> Void) {
        guard task == nil else { return }
        
        guard let image = getImage()?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completionHandler(nil)
            return
        }
        
        detectText(in: image)
    }
    
    func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
    
    func precessDetectedText(_ text: String) {
        defer {
            try? FileManager.default.removeItem(atPath: screenShotFilePath)
        }
        let sourceText = text
        let pasteBoard = NSPasteboard.general

        Task {
                do {
                    let translatedText = try await TranslationService.shared.translate(
                        sourceText: sourceText,
                        sourceLanguage: preferences.recongitionLanguage.languageCode(),
                        targetLanguage: preferences.translationTargetLanguage.languageCode()
                    )
                    
                    DispatchQueue.main.async {
                        pasteBoard.clearContents()
                        pasteBoard.setString(translatedText, forType: .string)
                        
                        self.showNotification(text: translatedText)
                    }
                } catch {
                    print("Translation error: \(error)")
                    pasteBoard.clearContents()
                    pasteBoard.setString(sourceText, forType: .string)
                    
                    self.showNotification(text: sourceText)
                }
            }
    }
    
    private func detectAndOpenURL(text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        matches?.forEach{ match in
            guard let range = Range(match.range, in: text),
                  case let urlStr = String(text[range]),
                  let url = URL(string: urlStr)
            else {return}
            
            NSWorkspace.shared.open(url)
        }
    }
    
    func detectText(in image: CGImage) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error detecting text: \(error)")
            } else {
                if let result = self.handleDetectionResults(results: request.results) {
                    self.precessDetectedText(result)
                }
            }
        }
        
        request.recognitionLanguages = [preferences.recongitionLanguage.languageCode()]
        request.recognitionLevel = .accurate
        
        performDetection(request: request, image: image)
    }
    
    private func performDetection(request: VNRecognizeTextRequest, image: CGImage) {
        let requests = [request]
        
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform(requests)
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    private func handleDetectionResults(results: [Any]?) -> String? {
          
        guard let results = results, results.count > 0 else {
            return nil
        }
        
        var output: String = ""
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    if !output.isEmpty {
                        output.append(preferences.ignoreLineBreaks ? " ":"\n")
                    }
                    output.append(text.string)
                }
            }
        }
        
        return output
    }
    
}

// MARK: Notifications
extension NLLBTranslator {
    func showNotification(text: String) {
        guard preferences.resultNotification else {return}
        let content = UNMutableNotificationContent()
        content.title = "NLLBTranslator"
        content.subtitle = "Captured text"
        content.body = text

        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: nil)

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        notificationCenter.add(request)
    }
}
