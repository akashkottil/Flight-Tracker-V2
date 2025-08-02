import Foundation

// MARK: - User Configuration Constants
struct UserConfig {
    
    // MARK: - App Configuration
    static let appCode = "d1_ios_flight"
    static let appName = "D2Flight"
    static let appVersion = "1.02"
    
    // MARK: - API Configuration
    static let defaultCountryCode = "IN"
    static let defaultCurrencyCode = "INR"
    static let defaultLanguageCode = "en-GB"
    
    // MARK: - User Creation Configuration
    static let defaultDeviceIdType = "idfa"
    static let defaultAcquiredRoute = "unknown"
    static let defaultSessionType = "api"
    static let defaultSessionRoute = "unknown"
    static let fallbackDeviceIdType = "uuid"
    
    // MARK: - Tracking Configuration
    static let maxRetries = 10
    static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    
    // MARK: - Debug Configuration
    #if DEBUG
    static let isDebugMode = true
    static let enableVerboseLogging = true
    #else
    static let isDebugMode = false
    static let enableVerboseLogging = false
    #endif
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let userId = "D2Flight_UserID"
        static let deviceId = "D2Flight_DeviceID"
        static let deviceIdType = "D2Flight_DeviceIDType"
        static let vendorId = "D2Flight_VendorID"
        static let pseudoId = "D2Flight_PseudoID"
        static let userCreated = "D2Flight_UserCreated"
        static let installDate = "D2Flight_InstallDate"
    }
    
    // MARK: - Helper Methods
    
    /// Get current country code from device locale with fallback
    static func getCurrentCountryCode() -> String {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier ?? defaultCountryCode
        } else {
            return Locale.current.regionCode ?? defaultCountryCode
        }
    }
    
    /// Get current language code from device locale with fallback
    static func getCurrentLanguageCode() -> String {
        if let languageCode = Locale.current.language.languageCode?.identifier {
            return "\(languageCode)-\(getCurrentCountryCode())"
        }
        return defaultLanguageCode
    }
    
    /// Get app display name
    static func getAppDisplayName() -> String {
        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }
        if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return bundleName
        }
        return appName
    }
    
    /// Get app version from bundle
    static func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return appVersion
    }
    
    /// Get build number from bundle
    static func getBuildNumber() -> String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1"
    }
    
    /// Get full app version string (version + build)
    static func getFullAppVersion() -> String {
        return "\(getAppVersion()) (\(getBuildNumber()))"
    }
    
    // MARK: - Validation Methods
    
    /// Validate if country code is valid (2 letter ISO code)
    static func isValidCountryCode(_ code: String) -> Bool {
        return code.count == 2 && code.allSatisfy { $0.isLetter }
    }
    
    /// Validate if currency code is valid (3 letter ISO code)
    static func isValidCurrencyCode(_ code: String) -> Bool {
        return code.count == 3 && code.allSatisfy { $0.isLetter }
    }
    
    /// Validate if language code is valid
    static func isValidLanguageCode(_ code: String) -> Bool {
        return code.contains("-") && code.count >= 5
    }
}
