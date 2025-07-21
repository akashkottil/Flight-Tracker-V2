import SwiftUI

struct TripTypeSelector: View {
    @ObservedObject var viewModel: SearchViewModel
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TripType.allCases, id: \.self) { type in
                Button(action: {
                    viewModel.selectTripType(type)
                }) {
                    Text(type.rawValue)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 22)
                        .frame(minWidth: 80)
                        .font(.system(size: 13))
                        .background(
                            ZStack {
                                if viewModel.tripType == type {
                                    Capsule()
                                        .fill(Color.white)
                                        .matchedGeometryEffect(id: "TAB", in: namespace)
                                }
                            }
                        )
                        .foregroundColor(viewModel.tripType == type ? Color("AppPrimaryColor") : Color.black)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 6) // Slightly reduced vertical padding
                .padding(.horizontal, 6) // Add inner padding to prevent touching edges
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity) // Allow container to expand
                .padding(.horizontal, 16) // Outer horizontal padding
                .padding(.top, 10)
    }
}
