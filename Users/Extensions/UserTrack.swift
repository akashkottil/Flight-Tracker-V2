import SwiftUI

// MARK: - View Extension for User Tracking
extension View {
    /// Track user events with session creation
    func trackUserEvent(
        _ eventType: UserEventType,
        vertical: UserVertical = .flight,
        tag: String? = nil,
        additionalData: [String: String]? = nil
    ) -> some View {
        return self.onTapGesture {
            UserManager.shared.createSession(
                eventType: eventType,
                vertical: vertical,
                tag: tag,
                additionalData: additionalData
            )
        }
    }
    
    /// Track button taps specifically
    func trackButtonTap(
        _ eventType: UserEventType,
        vertical: UserVertical = .flight,
        tag: String? = nil
    ) {
        UserManager.shared.createSession(
            eventType: eventType,
            vertical: vertical,
            tag: tag
        )
    }
}
