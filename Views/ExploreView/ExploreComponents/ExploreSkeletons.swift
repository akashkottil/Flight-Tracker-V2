// MARK: - Enhanced Shimmer Effect

import SwiftUICore
import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    var bounce: Bool = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.7),
                        Color.white.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .animation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: bounce),
                    value: phase
                )
            )
            .onAppear {
                phase = 300
            }
            .clipped()
    }
}

extension View {
    func shimmer(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}

// MARK: - Enhanced Skeleton Destination Card
struct EnhancedSkeletonDestinationCard: View {
    @State private var isAnimating = false
    @State private var breatheScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var cardAppeared = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Enhanced image placeholder with gradient - full height and left aligned
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray5),
                                Color(.systemGray6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 90)
                    .shimmer(duration: 1.5)
                
                // Floating icon animation
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.gray.opacity(0.4))
                    .scaleEffect(breatheScale)
            }
            .cornerRadius(12, corners: [.topLeft, .bottomLeft])
            
            // Enhanced text placeholders with padding only on the right side
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    // "Flights from" placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 12)
                        .shimmer(duration: 1.8)
                    
                    // Location name placeholder
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 140, height: 20)
                        .shimmer(duration: 1.6)
                    
                    // Direct/Connecting placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                        .shimmer(duration: 2.0)
                }
                
                Spacer()
                
                // Enhanced price placeholder
                VStack(alignment: .trailing, spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.systemGray4),
                                    Color(.systemGray3),
                                    Color(.systemGray4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray3).opacity(glowOpacity), lineWidth: 1)
                        )
                        .shimmer(duration: 1.4)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray6), lineWidth: 1)
                )
        )
        .scaleEffect(breatheScale)
        // Enhanced slide-in animations for skeleton
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 50)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.6)
            .delay(Double.random(in: 0...0.4)),
            value: cardAppeared
        )
        .onAppear {
            withAnimation {
                cardAppeared = true
            }
            
            // Continuous breathing animation
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.01
                glowOpacity = 0.1
            }
        }
    }
}



// MARK: - Enhanced Skeleton Flight Result Card - Exact Match to FlightResultCard
struct EnhancedSkeletonFlightResultCard: View {
    @State private var pulseOpacity: Double = 0.6
    @State private var breatheScale: CGFloat = 1.0
    
    // ADD: Parameter to control whether to show return section
    var isRoundTrip: Bool = true
    
    var body: some View {
        VStack(spacing: 5) {
            // Departure section - matching FlightResultCard structure exactly
            VStack(alignment: .leading, spacing: 8) {
                Text("Departure")
                    .font(.subheadline)
                    .foregroundColor(.clear) // Hidden but maintains spacing
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 70, height: 14)
                    )
                
                HStack {
                    // Date placeholder - matches "String(departureDate.dropLast(5))"
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray5), Color(.systemGray4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 85, height: 20) // Matches headline font size
                        .shimmer(duration: 1.6)
                    
                    Spacer()
                    
                    // Flight route section - matches HStack with origin, arrow, destination
                    HStack(spacing: 6) {
                        // Origin code placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(width: 35, height: 20) // Matches headline font
                            .shimmer(duration: 1.8)
                        
                        // Arrow placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray6))
                            .frame(width: 12, height: 8) // Small arrow size
                            .shimmer(duration: 1.4)
                        
                        // Destination code placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(width: 35, height: 20) // Matches headline font
                            .shimmer(duration: 1.8)
                    }
                    
                    Spacer()
                    
                    // Direct/Connecting status placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 70, height: 16) // Matches subheadline + fontWeight
                        .shimmer(duration: 2.0)
                }
            }
            .padding(.horizontal) // Matches FlightResultCard padding
            .padding(.vertical, 12) // Matches FlightResultCard padding
            
            // MODIFIED: Return section - only show for round trips (same structure as departure)
            if isRoundTrip {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Return")
                        .font(.subheadline)
                        .foregroundColor(.clear) // Hidden but maintains spacing
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 55, height: 14)
                        )
                    
                    HStack {
                        // Return date placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 85, height: 20) // Matches headline font size
                            .shimmer(duration: 1.6)
                        
                        Spacer()
                        
                        // Return route section
                        HStack(spacing: 6) {
                            // Destination code (return origin)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 35, height: 20)
                                .shimmer(duration: 1.8)
                            
                            // Arrow placeholder
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray6))
                                .frame(width: 12, height: 8)
                                .shimmer(duration: 1.4)
                            
                            // Origin code (return destination)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 35, height: 20)
                                .shimmer(duration: 1.8)
                        }
                        
                        Spacer()
                        
                        // Return direct status placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 70, height: 16)
                            .shimmer(duration: 2.0)
                    }
                }
                .padding(.horizontal) // Matches FlightResultCard padding
                .padding(.vertical, 12) // Matches FlightResultCard padding
            }
            
            // Divider - matching FlightResultCard exactly
            Divider()
                .padding(.horizontal, 16) // Exact match to FlightResultCard
            
            // Price section - matching FlightResultCard structure exactly
            HStack {
                VStack(alignment: .leading) {
                    // "Flights from" placeholder
                    Text("Flights from")
                        .font(.subheadline)
                        .foregroundColor(.clear) // Hidden but maintains spacing
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 14)
                                .shimmer(duration: 1.8)
                        )
                    
                    // Price placeholder - matching title2 + fontWeight(.bold)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.systemGray4),
                                    Color(.systemGray3),
                                    Color(.systemGray4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100, height: 28) // Matches title2 font size
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray3).opacity(0.3), lineWidth: 1)
                        )
                        .shimmer(duration: 1.4)
                    
                    // Trip duration placeholder - matching subheadline
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 90, height: 16) // Matches subheadline font
                        .shimmer(duration: 2.0)
                }
                
                Spacer()
                
                // Button placeholder - matching exact button dimensions
                ZStack {
                    RoundedRectangle(cornerRadius: 8) // Matches button cornerRadius
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 146, height: 46) // Exact match to button frame
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shimmer(duration: 1.6)
                    
                    // Button text placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 100, height: 16)
                }
            }
            .padding() // Matches FlightResultCard bottom padding
        }
        .background(Color.white) // Exact match to FlightResultCard background
        .cornerRadius(12) // Exact match to FlightResultCard cornerRadius
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Exact match to FlightResultCard shadow
        .padding(.horizontal,5) // Exact match to FlightResultCard padding
        .scaleEffect(breatheScale)
        .opacity(pulseOpacity)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 1.0
        }
        
        // Subtle breathing
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.01
        }
    }
}


// MARK: - Enhanced Detailed Flight Card Skeleton with Multi-City Support
struct EnhancedDetailedFlightCardSkeleton: View {
    @State private var shimmerOffset: CGFloat = -200
    @State private var glowIntensity: Double = 0.3
    @State private var breatheScale: CGFloat = 1.0
    @State private var cardAppeared = false
    
    // UPDATED: Support for different trip types
    let isRoundTrip: Bool
    let isMultiCity: Bool
    let multiCityLegsCount: Int
    

    // REPLACE the existing init with this enhanced version
    init(isRoundTrip: Bool = true, isMultiCity: Bool = false, multiCityLegsCount: Int = 0) {
        self.isRoundTrip = isRoundTrip
        self.isMultiCity = isMultiCity
        self.multiCityLegsCount = multiCityLegsCount
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Tags section with synchronized shimmer animation
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60 + CGFloat(index * 20), height: 24)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // UPDATED: Dynamic flight rows based on trip type
            if isMultiCity {
                // Multi-city: Show multiple flight legs
                ForEach(0..<max(2, multiCityLegsCount), id: \.self) { _ in
                    enhancedFlightRow()
                }
            } else if isRoundTrip {
                // Round trip: Show 2 flight rows
                enhancedFlightRow() // Outbound
                enhancedFlightRow() // Return
            } else {
                // One way: Show 1 flight row
                enhancedFlightRow() // Outbound only
            }
            
            Divider()
                .opacity(0.2)
                .padding(.horizontal, 16)
            
            // Enhanced bottom section with synchronized shimmer
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Airline placeholder with synchronized shimmer
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6).opacity(0.4), Color(.systemGray5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 120, height: 14)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                    
                    // Price with synchronized shimmer
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(.systemGray4).opacity(0.4),
                                        Color(.systemGray3).opacity(0.4),
                                        Color(.systemGray4).opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 22)
                            .modifier(ShimmerEffectt(offset: shimmerOffset))
                    }
                    
                    // Price detail with synchronized shimmer
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .frame(width: 140, height: 12)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(.systemGray5).opacity(0.3),
                                    Color(.systemGray4).opacity(0.1),
                                    Color(.systemGray5).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 8
        )
        .scaleEffect(breatheScale)
        // Enhanced bottom slide animation - starts from completely off-screen
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 300)
        .scaleEffect(cardAppeared ? 1.0 : 0.8)
        .animation(
            .spring(
                response: 0.8,
                dampingFraction: 0.6,
                blendDuration: 0.1
            ),
            value: cardAppeared
        )
        .onAppear {
            // Trigger card appearance immediately
            withAnimation {
                cardAppeared = true
            }
            startPremiumAnimations()
        }
    }
    
    @ViewBuilder
    private func enhancedFlightRow() -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Airline logo placeholder with synchronized shimmer
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray5).opacity(0.4),
                                Color(.systemGray4).opacity(0.3),
                                Color(.systemGray5).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray3).opacity(0.2), lineWidth: 1)
                    )
                    .modifier(ShimmerEffectt(offset: shimmerOffset))
                
                Image(systemName: "airplane")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray3))
                    .opacity(0.6)
            }
            
            // Departure section with synchronized shimmer
            VStack(alignment: .leading, spacing: 4) {
                // Time with synchronized shimmer
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5).opacity(0.4), Color(.systemGray4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 16)
                    .modifier(ShimmerEffectt(offset: shimmerOffset))
                
                // Code and date row with synchronized shimmer
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .frame(width: 30, height: 12)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                    
                    Circle()
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(width: 3, height: 3)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .frame(width: 40, height: 10)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                }
            }
            .frame(width: 75, alignment: .leading)
            
            Spacer()
            
            // Duration and status with synchronized shimmer
            VStack(spacing: 6) {
                // Duration with synchronized shimmer
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6).opacity(0.4))
                    .frame(width: 45, height: 10)
                    .modifier(ShimmerEffectt(offset: shimmerOffset))
                
                // Status with synchronized shimmer
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6).opacity(0.4))
                    .frame(width: 50, height: 10)
                    .modifier(ShimmerEffectt(offset: shimmerOffset))
            }
            
            Spacer()
            
            // Arrival section with synchronized shimmer
            VStack(alignment: .trailing, spacing: 4) {
                // Time with synchronized shimmer
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray4).opacity(0.4), Color(.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 16)
                    .modifier(ShimmerEffectt(offset: shimmerOffset))
                
                // Code and date row with synchronized shimmer
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .frame(width: 40, height: 10)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                    
                    Circle()
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(width: 3, height: 3)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6).opacity(0.4))
                        .frame(width: 30, height: 12)
                        .modifier(ShimmerEffectt(offset: shimmerOffset))
                }
            }
            .frame(width: 75, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func startPremiumAnimations() {
        // Synchronize shimmer across the card
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 200
        }
        
        // Glow pulse
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 0.8
        }
        
        // Subtle breathing
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.005
        }
    }
}

// MARK: - Enhanced Shimmer Effect for Synchronized Animation
struct ShimmerEffectt: ViewModifier {
    var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(content)
                .offset(x: offset)
            )
    }
}


