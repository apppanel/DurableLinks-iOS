import Foundation

public struct DurableLink: Sendable {
    let url: URL?                // The extracted deep link
    let utmParameters: [String: String] // UTM parameters
    let minimumAppVersion: String?      // Extracted from `imv`
    
    public init?(longLink: URL) {
        guard let components = URLComponents(url: longLink, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ Invalid long link URL")
            return nil
        }
        
        // Extract `link` parameter (actual deep link)
        let deepLink = queryItems.first(where: { $0.name == "link" })?.value.flatMap(URL.init)
        
        // Extract `imv` (minimum app version)
        let imv = queryItems.first(where: { $0.name == "imv" })?.value
        
        // Extract all UTM parameters dynamically
        var utmParams = [String: String]()
        for item in queryItems where item.name.starts(with: "utm_") {
            if let value = item.value {
                utmParams[item.name] = value
            }
        }

        self.url = deepLink
        self.utmParameters = utmParams
        self.minimumAppVersion = imv
    }
}
