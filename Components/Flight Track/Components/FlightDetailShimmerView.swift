//
//  FlightDetailShimmerView.swift
//  AllFlights
//
//  Created by Akash Kottil on 01/08/25.
//


import SwiftUI

struct FlightDetailShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                // Flight Info Header Shimmer
                HStack {
                    ShimmerRectangle(width: 34, height: 34, cornerRadius: 8)
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerRectangle(width: 80, height: 20, cornerRadius: 4)
                        ShimmerRectangle(width: 120, height: 16, cornerRadius: 4)
                    }
                    Spacer()
                    ShimmerRectangle(width: 70, height: 24, cornerRadius: 8)
                }
                
                // Dotted Line Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                    .padding(.vertical, 8)
                
                // Flight Route Timeline Shimmer
                HStack(alignment: .top, spacing: 16) {
                    // Timeline
                    VStack(spacing: 0) {
                        Spacer()
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 120)
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                        Spacer()
                    }
                    
                    // Flight details shimmer
                    VStack(alignment: .leading, spacing: 10) {
                        // Departure shimmer
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    ShimmerRectangle(width: 60, height: 34, cornerRadius: 6)
                                    ShimmerRectangle(width: 140, height: 12, cornerRadius: 4)
                                    ShimmerRectangle(width: 160, height: 12, cornerRadius: 4)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    ShimmerRectangle(width: 60, height: 20, cornerRadius: 4)
                                    ShimmerRectangle(width: 50, height: 12, cornerRadius: 4)
                                    ShimmerRectangle(width: 70, height: 10, cornerRadius: 4)
                                }
                            }
                        }
                        
                        // Duration shimmer
                        HStack {
                            ShimmerRectangle(width: 80, height: 20, cornerRadius: 10)
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                            Spacer()
                        }
                        
                        // Arrival shimmer
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    ShimmerRectangle(width: 60, height: 34, cornerRadius: 6)
                                    ShimmerRectangle(width: 140, height: 12, cornerRadius: 4)
                                    ShimmerRectangle(width: 160, height: 12, cornerRadius: 4)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    ShimmerRectangle(width: 60, height: 20, cornerRadius: 4)
                                    ShimmerRectangle(width: 50, height: 12, cornerRadius: 4)
                                    ShimmerRectangle(width: 70, height: 10, cornerRadius: 4)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .padding()
                
                // Updated info shimmer
                HStack {
                    ShimmerRectangle(width: 16, height: 16, cornerRadius: 8)
                    ShimmerRectangle(width: 120, height: 14, cornerRadius: 4)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.bottom, 20)
                
                // Status Cards Shimmer
                VStack(spacing: 12) {
                    FlightStatusCardShimmer()
                    
                    Divider()
                        .padding(.vertical, 20)
                    
                    FlightStatusCardShimmer()
                }
                
                // Airlines Info Shimmer
                VStack(alignment: .leading, spacing: 12) {
                    ShimmerRectangle(width: 100, height: 18, cornerRadius: 4)
                    VStack(spacing: 8) {
                        HStack {
                            ShimmerRectangle(width: 24, height: 24, cornerRadius: 12)
                            ShimmerRectangle(width: 140, height: 16, cornerRadius: 4)
                            Spacer()
                        }
                        HStack {
                            ShimmerRectangle(width: 24, height: 24, cornerRadius: 12)
                            ShimmerRectangle(width: 120, height: 16, cornerRadius: 4)
                            Spacer()
                        }
                        HStack {
                            ShimmerRectangle(width: 24, height: 24, cornerRadius: 12)
                            ShimmerRectangle(width: 160, height: 16, cornerRadius: 4)
                            Spacer()
                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1.4)
                )
                .cornerRadius(20)
                
                // About Destination Shimmer
                VStack(alignment: .leading, spacing: 12) {
                    ShimmerRectangle(width: 140, height: 18, cornerRadius: 4)
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerRectangle(width: .random(in: 200...300), height: 16, cornerRadius: 4)
                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1.4)
                )
                .cornerRadius(20)
                
                // Settings section shimmer
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ShimmerRectangle(width: 100, height: 18, cornerRadius: 4)
                        Spacer()
                        ShimmerRectangle(width: 44, height: 24, cornerRadius: 12)
                    }
                    Divider()
                    HStack {
                        ShimmerRectangle(width: 120, height: 18, cornerRadius: 4)
                        Spacer()
                        ShimmerRectangle(width: 44, height: 24, cornerRadius: 12)
                    }
                    Divider()
                    HStack {
                        ShimmerRectangle(width: 60, height: 18, cornerRadius: 4)
                        Spacer()
                        ShimmerRectangle(width: 20, height: 20, cornerRadius: 4)
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1.4)
                )
                .cornerRadius(20)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct FlightStatusCardShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShimmerRectangle(width: 180, height: 18, cornerRadius: 4)
            
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerRectangle(width: 80, height: 14, cornerRadius: 4)
                        ShimmerRectangle(width: 60, height: 20, cornerRadius: 4)
                        ShimmerRectangle(width: 70, height: 12, cornerRadius: 4)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        ShimmerRectangle(width: 100, height: 14, cornerRadius: 4)
                        ShimmerRectangle(width: 80, height: 20, cornerRadius: 4)
                        ShimmerRectangle(width: 90, height: 12, cornerRadius: 4)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerRectangle(width: 90, height: 14, cornerRadius: 4)
                        ShimmerRectangle(width: 70, height: 20, cornerRadius: 4)
                        ShimmerRectangle(width: 80, height: 12, cornerRadius: 4)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1.4)
        )
        .cornerRadius(20)
    }
}

struct ShimmerRectangle: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var startPoint = UnitPoint(x: -1.8, y: 0)
    @State private var endPoint = UnitPoint(x: 0, y: 0)
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.25),
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.25)
                    ],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    startPoint = UnitPoint(x: 1, y: 0)
                    endPoint = UnitPoint(x: 2.8, y: 0)
                }
            }
    }
}

// Preview
struct FlightDetailShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            FlightDetailShimmerView()
                .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}