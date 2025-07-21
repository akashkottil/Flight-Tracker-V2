import SwiftUI

struct FlightSearchStatusView: View {
    let isLoading: Bool
    let flightCount: Int
    let destinationName: String
    
    @State private var dotCount = 0
    @State private var showCheckmark = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var textOpacity: Double = 1
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            if isLoading {
                // Loading state with animated dots
                HStack(spacing: 4) {
                    Text("Looking for best flight deal to \(destinationName)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .opacity(textOpacity)
                    
                    // Animated dots
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .frame(width: 4, height: 4)
                                .foregroundColor(.primary)
                                .opacity(index < dotCount ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.5)
                                    .delay(Double(index) * 0.1),
                                    value: dotCount
                                )
                        }
                    }
                }
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dotCount = (dotCount + 1) % 4
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
            } else if showCheckmark {
                // Success checkmark animation
                HStack{
                    Text("Done")
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                            .scaleEffect(checkmarkScale)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(checkmarkScale)
                    }
                }
                .transition(.scale.combined(with: .opacity))
                
            } else {
                // Final state - flight count
                Text("\(flightCount) flights found")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoading)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCheckmark)
        .onChange(of: isLoading) { oldValue, newValue in
            if oldValue && !newValue && flightCount > 0 {
                // Loading just finished successfully
                showSuccessAnimation()
            }
        }
    }
    
    private func showSuccessAnimation() {
        // Show checkmark with bounce animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
            checkmarkScale = 1.2
        }
        
        // Scale down slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                checkmarkScale = 1.0
            }
        }
        
        // Fade out checkmark and show final text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCheckmark = false
            }
        }
    }
}

// MARK: - Usage Example
struct FlightSearchStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            FlightSearchStatusView(
                isLoading: true,
                flightCount: 0,
                destinationName: "Paris"
            )
            
            // Completed state
            FlightSearchStatusView(
                isLoading: false,
                flightCount: 42,
                destinationName: "Paris"
            )
        }
        .padding()
    }
}
