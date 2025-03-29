import Foundation

public struct DurableLinkComponents: Sendable {

    private let link: URL
    private let domain: String
    
    public var iOSParameters: DurableLinkIOSParameters = DurableLinkIOSParameters()
    public var androidParameters: DurableLinkAndroidParameters?
    public var iTunesConnectParameters: DurableLinkItunesConnectAnalyticsParameters?
    public var socialMetaTagParameters: DurableLinkSocialMetaTagParameters?
    public var options: DurableLinkComponentsOptions = DurableLinkComponentsOptions()
    public var otherPlatformParameters: DurableLinkOtherPlatformParameters?
    public var analyticsParameters: DurableLinkAnalyticsParameters?
    
    
    public init?(
        link: URL,
        domainURIPrefix: String,
        iOSParameters: DurableLinkIOSParameters = DurableLinkIOSParameters(),
        androidParameters: DurableLinkAndroidParameters? = nil,
        iTunesConnectParameters: DurableLinkItunesConnectAnalyticsParameters? = nil,
        socialMetaTagParameters: DurableLinkSocialMetaTagParameters? = nil,
        options: DurableLinkComponentsOptions = DurableLinkComponentsOptions(),
        otherPlatformParameters: DurableLinkOtherPlatformParameters? = nil,
        analyticsParameters: DurableLinkAnalyticsParameters? = nil
    ) {
        self.link = link

        guard let domainURIPrefixURL = URL(string: domainURIPrefix) else {
            print("FDLLog: Invalid domainURIPrefix. Please input a valid URL.")
            return nil
        }
        guard domainURIPrefixURL.scheme?.lowercased() == "https" else {
            print("FDLLog: Invalid domainURIPrefix scheme. Scheme needs to be https.")
            return nil
        }

        self.domain = domainURIPrefix
        self.iOSParameters = iOSParameters
        self.androidParameters = androidParameters
        self.iTunesConnectParameters = iTunesConnectParameters
        self.socialMetaTagParameters = socialMetaTagParameters
        self.options = options
        self.otherPlatformParameters = otherPlatformParameters
        self.analyticsParameters = analyticsParameters
    }

    public var url: URL? {
        let queryString = buildQueryDict().compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")

        return URL(string: "\(domain)/?\(queryString)")
    }
    
    private func buildQueryDict() -> [String: String] {
        var dict: [String: String] = ["link": link.absoluteString]
        
        let addParams = { (params: Encodable?) in
            guard let encodable = params,
                  let data = try? JSONEncoder().encode(encodable),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            for (key, value) in json {
                if let stringValue = value as? String {
                    dict[key] = stringValue
                } else if let numberValue = value as? NSNumber {
                    dict[key] = numberValue.stringValue
                }
            }
        }

        addParams(analyticsParameters)
        addParams(socialMetaTagParameters)
        addParams(iOSParameters)
        addParams(androidParameters)
        addParams(iTunesConnectParameters)
        addParams(otherPlatformParameters)
        
        return dict
    }
    
    public func shorten(completion: @escaping @Sendable (URL?, [String]?, Error?) -> Void) {
        guard let longURL = url else {
            let error = NSError(domain: "DurableLinkError", code: 0, userInfo: [
                NSLocalizedFailureReasonErrorKey: "Unable to produce long URL"
            ])
            completion(nil, nil, error)
            return
        }

        Task {
            await Self.shortenURL(longURL, options: options, completion: completion)
        }
    }

    
    public static func shortenURL(
        _ url: URL,
        options: DurableLinkComponentsOptions = DurableLinkComponentsOptions(pathLength: .unguessable),
        completion: @escaping @Sendable (URL?, [String]?, Error?) -> Void
    ) async {
        guard let delegate = await DurableLinkConfig.shared.shortenerDelegate else {
            #if DEBUG // Is this DEBUG check needed? Not confident assertions are stripped out in every build scheme and don't want to crash prod
            assertionFailure("No DurableLinkShortenerDelegate configured. You must set DurableLinkConfig.shared.shortenerDelegate before shortening URLs.")
            #endif

            let error = NSError(domain: "DurableLinkError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "No DurableLinkShortenerDelegate configured."
            ])
            completion(nil, nil, error)
            return
        }

        delegate.shortenURL(longURL: url, options: options, completion: completion)
    }
}
