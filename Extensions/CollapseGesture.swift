import SwiftUI

extension View {
    /// Adds a drag gesture that collapses/expands the search card with haptic feedback
    /// - Parameter isCollapsed: Binding to the collapse state
    /// - Returns: View with the collapse gesture applied
    func collapseSearchCardOnDrag(isCollapsed: Binding<Bool>) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { value in
                    let verticalMovement = value.translation.height
                    
                    // Only collapse when scrolling DOWN (negative height = content moving up)
                    if verticalMovement < -15 && !isCollapsed.wrappedValue {
                        // ADD: Haptic feedback for collapsing
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCollapsed.wrappedValue = true
                        }
                    }
                    // Expand when scrolling UP (positive height = content moving down)
                    else if verticalMovement > 30 && isCollapsed.wrappedValue {
                        // ADD: Haptic feedback for expanding
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCollapsed.wrappedValue = false
                        }
                    }
                }
        )
    }
}
