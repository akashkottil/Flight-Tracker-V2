//
//  FAShimmerAlertView.swift
//  AllFlights
//
//  Created by Akash Kottil on 01/07/25.
//


import SwiftUI

struct FAShimmerAlertView: View {
    
    // Number of shimmer cards to show (default 3)
    let shimmerCount: Int
    
    @State private var showLocationSheet = false
    @State private var showMyAlertsSheet = false
    
    init(shimmerCount: Int = 3) {
        self.shimmerCount = shimmerCount
    }
    
    var body: some View {
        ZStack {
            GradientColor.BlueWhite
                .ignoresSafeArea()
            VStack {
//                FAShimmerHeader()
                FAheader()
                
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
//                            VStack(alignment: .leading) {
//                                // Shimmer for title text
//                                Rectangle()
//                                    .fill(Color.gray.opacity(0.3))
//                                    .frame(width: 200, height: 24)
//                                    .clipShape(RoundedRectangle(cornerRadius: 4))
//                                    .overlay(shimmerOverlay())
//                                
//                                // Shimmer for subtitle text
//                                Rectangle()
//                                    .fill(Color.gray.opacity(0.25))
//                                    .frame(width: 160, height: 16)
//                                    .clipShape(RoundedRectangle(cornerRadius: 3))
//                                    .overlay(shimmerOverlay())
//                                    .padding(.top, 4)
//                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Display shimmer cards
                        ForEach(0..<shimmerCount, id: \.self) { index in
                            FAShimmerCard()
                                .padding()
                                .opacity(1.0 - (Double(index) * 0.1)) // Slight fade for stacked effect
                        }
                        
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
            
            // Fixed bottom button (disabled state with shimmer effect)
//            VStack {
//                Spacer()
//                
//                HStack(spacing: 0) {
//                    // Add new alert button (disabled)
//                    Button(action: {
//                        // Disabled during loading
//                    }) {
//                        HStack {
//                            Rectangle()
//                                .fill(Color.white.opacity(0.3))
//                                .frame(width: 16, height: 16)
//                                .clipShape(RoundedRectangle(cornerRadius: 2))
//                            
//                            Rectangle()
//                                .fill(Color.white.opacity(0.3))
//                                .frame(width: 80, height: 16)
//                                .clipShape(RoundedRectangle(cornerRadius: 2))
//                        }
//                        .padding()
//                    }
//                    .disabled(true)
//                    
//                    // Vertical divider
//                    Rectangle()
//                        .fill(Color.white.opacity(0.4))
//                        .frame(width: 1, height: 50)
//                    
//                    // Hamburger button (disabled)
//                    Button(action: {
//                        // Disabled during loading
//                    }) {
//                        HStack {
//                            Rectangle()
//                                .fill(Color.white.opacity(0.3))
//                                .frame(width: 20, height: 16)
//                                .clipShape(RoundedRectangle(cornerRadius: 2))
//                        }
//                        .padding()
//                    }
//                    .disabled(true)
//                }
//                .foregroundColor(.white)
//                .font(.system(size: 18))
//                .background(Color("FABlue").opacity(0.8)) // Slightly faded during loading
//                .cornerRadius(10)
//                .padding(.horizontal, 20)
//                .padding(.bottom, 20)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
//            }
        }
    }
    
    // MARK: - Shimmer Animation
    
    @State private var shimmerOffset: CGFloat = -300
    
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
            .onAppear {
                startShimmerAnimation()
            }
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
struct FAShimmerAlertView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Loading Flight Alerts...")
                .font(.headline)
                .foregroundColor(.gray)
            
            FAShimmerAlertView()
            
            Text("With Different Card Count")
                .font(.headline)
                .foregroundColor(.gray)
            
            FAShimmerAlertView(shimmerCount: 2)
        }
    }
}

#Preview {
    FAShimmerAlertView()
}

#Preview("Single Card Loading") {
    FAShimmerAlertView(shimmerCount: 1)
}

#Preview("Many Cards Loading") {
    FAShimmerAlertView(shimmerCount: 5)
}
