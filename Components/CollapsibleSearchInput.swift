import SwiftUI

struct CollapsibleSearchInput: View {
    @StateObject private var viewModel = SearchViewModel()
    @Namespace private var animation
    
    // Binding to external isExpanded state (from HomeView)
        @Binding var isExpanded: Bool
    
    // Scroll offset tracking
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    
    var body: some View {
        ZStack {
            if isExpanded {
                // Expanded search input
                expandedView
                    .transition(.opacity)
            } else {
                // Collapsed search input
                collapsedView
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.spring(), value: isExpanded)
    }
    
    private var expandedView: some View {
        SearchInput()
            .matchedGeometryEffect(id: "searchContainer", in: animation)
    }
    
    
    // First, define a custom shape for asymmetric corner radii
    struct CustomRoundedRectangle: Shape {
        var cornerRadius: CGFloat
        var corners: UIRectCorner
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect,
                                   byRoundingCorners: corners,
                                   cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            return Path(path.cgPath)
        }
    }
    
    
    private var collapsedView: some View {
        HStack {
            // Route info with icons
            // Route info with icons
                    HStack(spacing: 4) {
                        Text("\(viewModel.originCode) - \(viewModel.destinationCode)")
                            .matchedGeometryEffect(id: "routeText", in: animation)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("· \(viewModel.formatTripDate())")
                            .matchedGeometryEffect(id: "dateText", in: animation)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 10)
                    .padding(.vertical, 5)
                    .matchedGeometryEffect(id: "leftContent", in: animation)

                    Spacer()

                    // Search button with modified left corners
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = true
                        }
                    }) {
                        Text("Search")
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                    }
                    .background(Color.orange)
                    .clipShape(
                        CustomRoundedRectangle(
                            cornerRadius: 20,
                            corners: [.topRight, .bottomRight] // Full radius on right side
                        )
                    )
                    .clipShape(
                        CustomRoundedRectangle(
                            cornerRadius: 5, // Reduced radius on left side
                            corners: [.topLeft, .bottomLeft]
                        )
                    )
                    .foregroundColor(.white)
                    .matchedGeometryEffect(id: "searchButton", in: animation)
                }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(Color.white.cornerRadius(20))
                .matchedGeometryEffect(id: "searchBackground", in: animation)
        )
        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }
    }
}

// Extension for SearchViewModel
extension SearchViewModel {
    func formatTripDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: startDate)
    }
}


struct CollapsibleSearchInput_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var isExpanded = false

        var body: some View {
            CollapsibleSearchInput(isExpanded: $isExpanded)
                .padding()
                .background(Color(.systemGroupedBackground))
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
