import SwiftUI
import Foundation

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var isFirstLaunch: Bool
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowPushNotificationModal: Bool = false
    
    private let firstLaunchKey = "app_first_launch"
    private let onboardingCompletedKey = "onboarding_completed"
    private let pushNotificationShownKey = "push_notification_shown" // NEW: Track if modal was already shown
    
    private init() {
        // Check if this is the first launch
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        
        // If it's first launch, mark it as not first launch anymore
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
    }
    
    // NEW: Check if push notification modal was already shown
    private var hasPushNotificationBeenShown: Bool {
        return UserDefaults.standard.bool(forKey: pushNotificationShownKey)
    }
    
    // NEW: Mark push notification modal as shown
    private func markPushNotificationAsShown() {
        UserDefaults.standard.set(true, forKey: pushNotificationShownKey)
    }
    
    func completeAuthentication() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        // Only show push notification modal if it hasn't been shown before
        if !hasPushNotificationBeenShown {
            shouldShowPushNotificationModal = true
        }
    }
    
    func skipAuthentication() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        // Only show push notification modal if it hasn't been shown before
        if !hasPushNotificationBeenShown {
            shouldShowPushNotificationModal = true
        }
    }
    
    func pushNotificationModalDismissed() {
        shouldShowPushNotificationModal = false
        markPushNotificationAsShown() // NEW: Mark as shown when dismissed
    }
}
