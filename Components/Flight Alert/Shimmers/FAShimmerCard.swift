//
//  FAShimmerCard.swift
//  AllFlights
//
//  Created by Akash Kottil on 01/07/25.
//


import SwiftUI

struct FAShimmerCard: View {
    @State private var shimmerOffset: CGFloat = -300
    
    var body: some View {
        VStack(spacing: 0) {
            // Top image section with shimmer
            ZStack(alignment: .topLeading) {
                // Shimmer placeholder for image
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        shimmerOverlay()
                    )
                
                // Price drop badge shimmer
                HStack {
                    VStack {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 12, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius:12))
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 50, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            shimmerOverlay()
                        )
                    }
                    Spacer()
                }
                .padding(8)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            
            // Content section with shimmer
            VStack(alignment: .leading) {
                HStack {
                    VStack(spacing: 0) {
                        // Departure circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                        // Connecting line
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 24)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        // Arrival circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Origin airport shimmer
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(shimmerOverlay())
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 120, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(shimmerOverlay())
                        }
                        
                        // Destination airport shimmer
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(shimmerOverlay())
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(width: 140, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(shimmerOverlay())
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            
            Divider()
                .padding(.vertical, 16)
            
            // Bottom section with pricing shimmer
            HStack {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(shimmerOverlay())
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Original price shimmer (strikethrough)
                        Rectangle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 60, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(shimmerOverlay())
                        
                        // Current price shimmer
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(shimmerOverlay())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    // MARK: - Shimmer Animation
    
    private func shimmerOverlay() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.2),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(Angle(degrees: 15))
            .offset(x: shimmerOffset)
            .clipped()
    }
    
    private func startShimmerAnimation() {
        withAnimation(
            Animation
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 300
        }
    }
}

// MARK: - Preview
struct FAShimmerCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
//            Text("Loading Flight Alert...")
//                .font(.headline)
//                .foregroundColor(.gray)
            
//            FAShimmerCard()
//                .padding()
            
//            Text("Multiple Loading Cards")
//                .font(.headline)
//                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                FAShimmerCard()
                FAShimmerCard()
                FAShimmerCard()
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Flight Alert Loading...")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.gray)
        
        FAShimmerCard()
            .padding()
        
        // Show comparison with multiple cards
        VStack(spacing: 12) {
            FAShimmerCard()
            FAShimmerCard()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
