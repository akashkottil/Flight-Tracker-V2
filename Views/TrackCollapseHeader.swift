import SwiftUI

struct TrackCollapseHeader: View {
    let fromText: String
    let toText: String
    let dateText: String
    let passengerCount: Int
    let searchCardNamespace: Namespace.ID
    let onTap: () -> Void
    let handleBackNavigation: () -> Void
    let shouldShowBackButton: Bool

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
                    // Back button or spacer
                    HStack {
                        if shouldShowBackButton {
                            Button(action: handleBackNavigation) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .matchedGeometryEffect(id: "backButton", in: searchCardNamespace)
                        } else {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.clear)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .frame(width: 30)

                    Spacer()

                    // Content display
                    HStack(spacing: 8) {
                        Text("\(fromText) - \(toText)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 4, height: 4)

                        Text(dateText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)


                    }
                    .matchedGeometryEffect(id: "searchContent", in: searchCardNamespace)

                    Spacer()

                    // Right spacer
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.clear)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(width: 30)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .padding(.top, 5)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .matchedGeometryEffect(id: "cardBackground", in: searchCardNamespace)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Color("searchcardBackground")
                        .frame(height: geo.size.height+20)
                    Color("scroll")
                }
                .edgesIgnoringSafeArea(.all)
            }
        )
    }
}

// MARK: - Preview
struct TrackCollapseHeader_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        TrackCollapseHeader(
            fromText: "SFO",
            toText: "JFK",
            dateText: "20 Jun",
            passengerCount: 2,
            searchCardNamespace: ns,
            onTap: {},
            handleBackNavigation: {},
            shouldShowBackButton: true
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
