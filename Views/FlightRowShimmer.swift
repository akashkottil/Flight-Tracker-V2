import SwiftUI

struct FlightRowShimmer: View {
    // Animation for shimmer effect
    @State private var shimmerAnimation = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Shimmering image
            Rectangle()
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .shimmerEffect()

            VStack(alignment: .leading, spacing: 2) {
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

            VStack(alignment: .center, spacing: 2) {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 100, height: 14)
                    .cornerRadius(4)
                    .shimmerEffect()

                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .cornerRadius(4)
                    .shimmerEffect()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 100, height: 14)
                    .cornerRadius(4)
                    .shimmerEffect()

                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .cornerRadius(4)
                    .shimmerEffect()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 70, height: 16)
                    .cornerRadius(10)
                    .shimmerEffect()

                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 60, height: 12)
                    .cornerRadius(4)
                    .shimmerEffect()
            }
            .frame(width: 70, height: 34)
        }
        .padding(.vertical, 12)
        .animation(.linear(duration: 1.5).repeatForever(autoreverses: true), value: shimmerAnimation)
        .onAppear {
            shimmerAnimation.toggle()
        }
    }
}

extension View {
    // Shimmer effect modifier
    func shimmerEffect() -> some View {
        self
            .modifier(ShimmerEffect())
    }
}

struct FlightShimmerEffect: ViewModifier {
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

struct FlightRowShimmer_Previews: PreviewProvider {
    static var previews: some View {
        FlightRowShimmer()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
