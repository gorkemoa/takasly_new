import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
    let sharedSuiteName = "group.com.rivorya.takaslyapp"
    var pathData: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Kullanıcıya bir şeylerin hazırlandığını hissettirelim
        view.backgroundColor = .white
        let label = UILabel()
        label.text = "Takasly Hazırlanıyor..."
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
        
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        
        let dispatchGroup = DispatchGroup()
        for item in items {
            guard let attachments = item.attachments else { continue }
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    dispatchGroup.enter()
                    attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        if let url = data as? URL {
                            self?.saveFile(url)
                        }
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.openMainApp()
        }
    }

    private func saveFile(_ url: URL) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedSuiteName) else { return }
        let fileName = "shared_\(UUID().uuidString).jpg"
        let destURL = containerURL.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: url, to: destURL)
        pathData.append(destURL.path)
        
        let defaults = UserDefaults(suiteName: sharedSuiteName)
        defaults?.set(pathData, forKey: "share_images")
        defaults?.synchronize()
    }

    private func openMainApp() {
        var responder: UIResponder? = self
        let selectorOpenURL = sel_registerName("openURL:")
        let url = URL(string: "takasly://share")!

        while responder != nil {
            if responder!.responds(to: selectorOpenURL) {
                responder!.perform(selectorOpenURL, with: url)
                break
            }
            responder = responder?.next
        }
        
        // Extension'ı kapat
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
