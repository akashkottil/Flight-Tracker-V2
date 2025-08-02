import Foundation
import UIKit
import Combine
import AdSupport

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userId: Int? = nil
    @Published var currentSessionId: Int? = nil
    @Published var isUserCreated: Bool = false
    
    private let userApi = UserApi.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadStoredUserData()
    }
    
    // MARK: - Public Methods
    
    /// Initialize user on app launch
    func initializeUser() {
        if isUserCreated, let storedUserId = userId {
            if UserConfig.enableVerboseLogging {
                print("👤 User already exists with ID: \(storedUserId)")
            }
            // Create initial session for app launch
//            createSession(eventType: .appLaunch, vertical: .flight)
        } else {
            if UserConfig.enableVerboseLogging {
                print("👤 Creating new user...")
            }
            createNewUser()
        }
    }
    
    /// Create a new session for user events
    func createSession(
        eventType: UserEventType,
        vertical: UserVertical = .flight,
        tag: String? = nil,
        additionalData: [String: String]? = nil
    ) {
        guard let userId = userId else {
            print("⚠️ Cannot create session: User ID not available")
            return
        }
        
        let request = SessionCreationRequest(
            user_id: userId,
            type: UserConfig.defaultSessionType,
            tag: tag ?? eventType.rawValue,
            route: UserConfig.defaultSessionRoute,
            vertical: vertical.rawValue,
            country_code: UserConfig.getCurrentCountryCode(),
            ad_id: additionalData?["ad_id"],
            adgroup_id: additionalData?["adgroup_id"],
            campaign_id: additionalData?["campaign_id"],
            campaign_group_id: additionalData?["campaign_group_id"],
            account_id: additionalData?["account_id"],
            ad_objective_name: additionalData?["ad_objective_name"],
            gclid: additionalData?["gclid"],
            fbclid: additionalData?["fbclid"],
            msclkid: additionalData?["msclkid"]
        )
        
        userApi.createSession(request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.currentSessionId = response.user_session_id
                    if UserConfig.enableVerboseLogging {
                        print("✅ Session created for event: \(eventType.rawValue)")
                        print("   User ID: \(userId)")
                        print("   Session ID: \(response.user_session_id)")
                        print("   Type: \(request.type)")
                        print("   Tag: \(request.tag ?? "none")")
                        print("   Route: \(request.route)")
                        print("   Vertical: \(request.vertical)")
                        print("   Country: \(request.country_code)")
                    }
                case .failure(let error):
                    print("❌ Failed to create session for event \(eventType.rawValue): \(error)")
                }
            }
        }
    }
    
    /// Convenience method for search button tracking
    func trackSearchButtonClick(vertical: UserVertical = .flight) {
        createSession(
            eventType: .searchButtonClick,
            vertical: vertical,
            tag: "search"
        )
    }
    
    /// Convenience method for flight search tracking
    func trackFlightSearch() {
        createSession(
            eventType: .flightSearch,
            vertical: .flight,
            tag: "flight_search"
        )
    }
    
    /// Convenience method for hotel search tracking
    func trackHotelSearch() {
        createSession(
            eventType: .hotelSearch,
            vertical: .hotel,
            tag: "hotel_search"
        )
    }
    
    /// Convenience method for rental search tracking
    func trackRentalSearch() {
        createSession(
            eventType: .rentalSearch,
            vertical: .car,
            tag: "rental_search"
        )
    }
    
    // MARK: - Private Methods
    
    private func createNewUser() {
        let (deviceId, deviceIdType) = getOrCreateDeviceId()
        let vendorId = getOrCreateVendorId()
        let pseudoId = getOrCreatePseudoId()
        
        let request = UserCreationRequest(
            device_id: deviceId,
            device_id_type: deviceIdType,
            app: UserConfig.appCode,
            vendor_id: vendorId,
            pseudo_id: pseudoId,
            email: nil,
            acquired_route: UserConfig.defaultAcquiredRoute,
            referrer_url: nil
        )
        
        if UserConfig.enableVerboseLogging {
            print("👤 User Creation Parameters:")
            print("   Device ID: \(deviceId)")
            print("   Device ID Type: \(deviceIdType)")
            print("   App: \(request.app)")
            print("   Vendor ID: \(vendorId)")
            print("   Pseudo ID: \(pseudoId)")
            print("   Acquired Route: \(request.acquired_route)")
        }
        
        userApi.createUser(request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.handleUserCreationSuccess(response)
                case .failure(let error):
                    self?.handleUserCreationFailure(error)
                }
            }
        }
    }
    
    private func handleUserCreationSuccess(_ response: UserCreationResponse) {
        userId = response.user_id
        isUserCreated = true
        
        // Store in UserDefaults using config keys
        userDefaults.set(response.user_id, forKey: UserConfig.UserDefaultsKeys.userId)
        userDefaults.set(true, forKey: UserConfig.UserDefaultsKeys.userCreated)
        userDefaults.set(Date(), forKey: UserConfig.UserDefaultsKeys.installDate)
        
        print("✅ User created and stored successfully with ID: \(response.user_id)")
        
        // Create initial session for app launch
//        createSession(eventType: .appLaunch, vertical: .flight)
    }
    
    private func handleUserCreationFailure(_ error: Error) {
        print("❌ User creation failed: \(error)")
        // You might want to retry logic here or handle gracefully
    }
    
    private func loadStoredUserData() {
        userId = userDefaults.object(forKey: UserConfig.UserDefaultsKeys.userId) as? Int
        isUserCreated = userDefaults.bool(forKey: UserConfig.UserDefaultsKeys.userCreated)
        
        // Load device ID type for debugging/reference
        let deviceIdType = userDefaults.string(forKey: UserConfig.UserDefaultsKeys.deviceIdType) ?? "unknown"
        
        if isUserCreated && UserConfig.enableVerboseLogging {
            print("📱 Loaded stored user data - ID: \(userId ?? -1), Device Type: \(deviceIdType)")
        }
    }
    
    // MARK: - Device ID Generation with Fallback
    
    private func getOrCreateDeviceId() -> (deviceId: String, deviceIdType: String) {
        // Check if we already have stored values
        if let storedDeviceId = userDefaults.string(forKey: UserConfig.UserDefaultsKeys.deviceId),
           let storedDeviceIdType = userDefaults.string(forKey: UserConfig.UserDefaultsKeys.deviceIdType) {
            if UserConfig.enableVerboseLogging {
                print("📱 Using stored device ID: \(storedDeviceId) (type: \(storedDeviceIdType))")
            }
            return (storedDeviceId, storedDeviceIdType)
        }
        
        // Collect device ID with fallback logic
        var deviceId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        var deviceIdType = UserConfig.defaultDeviceIdType
        
        // Check if IDFA is unavailable (all zeros means no tracking permission)
        if deviceId == "00000000-0000-0000-0000-000000000000" {
            deviceIdType = UserConfig.fallbackDeviceIdType
            deviceId = UUID().uuidString
            if UserConfig.enableVerboseLogging {
                print("📱 IDFA unavailable, using UUID fallback")
            }
        } else if UserConfig.enableVerboseLogging {
            print("📱 IDFA available and valid")
        }
        
        // Store both values for future use
        userDefaults.set(deviceId, forKey: UserConfig.UserDefaultsKeys.deviceId)
        userDefaults.set(deviceIdType, forKey: UserConfig.UserDefaultsKeys.deviceIdType)
        
        if UserConfig.enableVerboseLogging {
            print("📱 Generated device ID: \(deviceId) (type: \(deviceIdType))")
        }
        return (deviceId, deviceIdType)
    }
    
    private func getOrCreateVendorId() -> String {
        if let storedVendorId = userDefaults.string(forKey: UserConfig.UserDefaultsKeys.vendorId) {
            return storedVendorId
        }
        
        // Use iOS Vendor Identifier or generate random UUID
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        userDefaults.set(vendorId, forKey: UserConfig.UserDefaultsKeys.vendorId)
        
        if UserConfig.enableVerboseLogging {
            print("🏭 Generated vendor ID: \(vendorId)")
        }
        return vendorId
    }
    
    private func getOrCreatePseudoId() -> String {
        if let storedPseudoId = userDefaults.string(forKey: UserConfig.UserDefaultsKeys.pseudoId) {
            return storedPseudoId
        }
        
        let pseudoId = generateRandomPseudoId()
        userDefaults.set(pseudoId, forKey: UserConfig.UserDefaultsKeys.pseudoId)
        
        if UserConfig.enableVerboseLogging {
            print("🎭 Generated pseudo ID: \(pseudoId)")
        }
        return pseudoId
    }
    
    // MARK: - ID Generators
    
    private func generateRandomPseudoId() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<21).map { _ in chars.randomElement()! })
    }
    
    // MARK: - Utility Methods
    
    /// Check if user exists and is valid
    var isValidUser: Bool {
        return isUserCreated && userId != nil
    }
    
    /// Get install date
    var installDate: Date? {
        return userDefaults.object(forKey: UserConfig.UserDefaultsKeys.installDate) as? Date
    }
    
    /// Clear all user data (for testing or logout)
    func clearUserData() {
        userDefaults.removeObject(forKey: UserConfig.UserDefaultsKeys.userId)
        userDefaults.removeObject(forKey: UserConfig.UserDefaultsKeys.userCreated)
        userDefaults.removeObject(forKey: UserConfig.UserDefaultsKeys.installDate)
        userDefaults.removeObject(forKey: UserConfig.UserDefaultsKeys.deviceIdType)
        // Keep device-related IDs as they should persist across app sessions
        
        userId = nil
        currentSessionId = nil
        isUserCreated = false
        
        print("🗑️ User data cleared")
    }
    
    /// Get app information for debugging
    func getAppInfo() -> [String: Any] {
        return [
            "app_code": UserConfig.appCode,
            "app_name": UserConfig.getAppDisplayName(),
            "app_version": UserConfig.getFullAppVersion(),
            "country_code": UserConfig.getCurrentCountryCode(),
            "language_code": UserConfig.getCurrentLanguageCode(),
            "is_debug": UserConfig.isDebugMode
        ]
    }
}
