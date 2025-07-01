//
//  FAShimmerHeader.swift
//  AllFlights
//
//  Created by Akash Kottil on 01/07/25.
//


import SwiftUI

struct FAShimmerHeader: View {
    @State private var shimmerOffset: CGFloat = -300
    
    var body: some View {
        VStack {
            HStack {
                // Logo shimmer placeholder
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 120, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(shimmerOverlay())
                
                Spacer()
                
                // Passenger count shimmer
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(shimmerOverlay())
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 12, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .overlay(shimmerOverlay())
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 10)
        }
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
                        Color.white.opacity(0.6),
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
struct FAShimmerHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Original Header")
                .font(.headline)
            
            // Show comparison with original if available
            ZStack {
                GradientColor.BlueWhite
                VStack {
                    FAShimmerHeader()
                    Spacer()
                }
            }
            .frame(height: 100)
            
            Text("Loading State")
                .font(.headline)
                .foregroundColor(.gray)
            
            ZStack {
                Color.blue.opacity(0.8)
                VStack {
                    FAShimmerHeader()
                    Spacer()
                }
            }
            .frame(height: 100)
        }
    }
}

#Preview {
    ZStack {
        GradientColor.BlueWhite
            .ignoresSafeArea()
        
        VStack {
            FAShimmerHeader()
            Spacer()
        }
    }
}

#Preview("On Blue Background") {
    ZStack {
        Color("FABlue")
            .ignoresSafeArea()
        
        VStack {
            FAShimmerHeader()
            Spacer()
        }
    }
}