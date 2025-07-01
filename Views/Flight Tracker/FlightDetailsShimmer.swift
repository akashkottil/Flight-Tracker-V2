import SwiftUI

struct FlightDetailsShimmer: View {
    // Animation for shimmer effect
    @State private var shimmerAnimation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Loading Skeleton View
                VStack {
                    // Flight Info Header
                    HStack {
                        // Shimmering image for airline logo
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 34, height: 34)
                            .cornerRadius(8)
                            .shimmerEffect()

                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(width: 100, height: 16)
                                .cornerRadius(4)
                                .shimmerEffect()

                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(width: 80, height: 14)
                                .cornerRadius(4)
                                .shimmerEffect()
                        }
                        Spacer()

                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 60, height: 18)
                            .cornerRadius(8)
                            .shimmerEffect()
                    }
                    .padding(.bottom, 10)
                    
                    Image("DottedLine")
                        .resizable()
                        .frame(height: 1)
                        .foregroundColor(.gray)
                    
                    // Flight Route Timeline
                    HStack(alignment: .top, spacing: 16) {
//                        VStack(spacing: 0) {
//                            Spacer()
//                            Circle()
//                                .stroke(Color.primary, lineWidth: 1)
//                                .frame(width: 8, height: 8)
//                            Rectangle()
//                                .fill(Color.primary)
//                                .frame(width: 1, height: 120)
//                                .padding(.top, 4)
//                                .padding(.bottom, 4)
//                            Circle()
//                                .stroke(Color.primary, lineWidth: 1)
//                                .frame(width: 8, height: 8)
//                            Spacer()
//                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            // Departure
                            VStack(alignment: .leading, spacing: 12) {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 34)
                                    .cornerRadius(4)
                                    .shimmerEffect()

                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 80, height: 14)
                                    .cornerRadius(4)
                                    .shimmerEffect()
                            }
                            
                            // Duration (centered between departure and arrival)
                            HStack {
                                Spacer()
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 120, height: 12)
                                    .cornerRadius(4)
                                    .shimmerEffect()
                                Spacer()
                            }

                            // Arrival
                            VStack(alignment: .leading, spacing: 12) {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 34)
                                    .cornerRadius(4)
                                    .shimmerEffect()

                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 80, height: 14)
                                    .cornerRadius(4)
                                    .shimmerEffect()
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    
                    Divider()
                        .padding(.bottom, 20)

                    // Status Cards
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 16) {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 16)
                                .cornerRadius(8)
                                .shimmerEffect()

                            VStack(alignment: .leading, spacing: 12) {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 16)
                                    .cornerRadius(4)
                                    .shimmerEffect()

                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 14)
                                    .cornerRadius(4)
                                    .shimmerEffect()
                            }

                            Divider()
                                .padding(.vertical, 20)

                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 16)
                                .cornerRadius(8)
                                .shimmerEffect()

                            VStack(alignment: .leading, spacing: 12) {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 16)
                                    .cornerRadius(4)
                                    .shimmerEffect()

                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 100, height: 14)
                                    .cornerRadius(4)
                                    .shimmerEffect()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

//extension View {
//    // Shimmer effect modifier
//    func shimmerEffect() -> some View {
//        self
//            .modifier(ShimmerEffect())
//    }
//}

struct DetailsShimmerEffect: ViewModifier {
    @State private var animation = false

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(70))
                .offset(x: animation ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    animation.toggle()
                }
            }
    }
}

struct FlightDetailsShimmer_Previews: PreviewProvider {
    static var previews: some View {
        FlightDetailsShimmer()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
