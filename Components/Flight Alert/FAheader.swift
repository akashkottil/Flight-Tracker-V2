import SwiftUI

struct FAheader: View {
    
    // ADDED: Computed property for passenger display text
    private var passengerDisplayText: String {
        let totalPassengers = adultsCount + childrenCount
        return "\(totalPassengers)"
    }
    
    @Binding var adultsCount: Int
    @Binding var childrenCount: Int
    @Binding var selectedCabinClass: String
    @Binding var childrenAges: [Int?]
    
    @State private var showPassengerSelector = false
    
    // ADD: Callback for when passenger button is tapped
    let onPassengerTap: () -> Void
    
    init(
        adultsCount: Binding<Int> = .constant(1),
        childrenCount: Binding<Int> = .constant(0),
        selectedCabinClass: Binding<String> = .constant("Economy"),
        childrenAges: Binding<[Int?]> = .constant([]),
        onPassengerTap: @escaping () -> Void = {}
    ) {
        self._adultsCount = adultsCount
        self._childrenCount = childrenCount
        self._selectedCabinClass = selectedCabinClass
        self._childrenAges = childrenAges
        self.onPassengerTap = onPassengerTap
    }
    
    var body: some View {
        VStack{
            HStack{
                Image("FALogoWhite")
                Spacer()
                
                // UPDATED: Make passenger section tappable
                Button(action: {
                    showPassengerSelector = true
                }) {
                    HStack{
                        Image("FAPassenger")
                        Text("\(adultsCount + childrenCount)")
                            .foregroundColor(.black) // UPDATED: Use dynamic count
                    }
                    .padding(.vertical,8)
                    .padding(.horizontal,10)
                    .background(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle()) // ADDED: Remove default button styling
            }
            .padding(.horizontal,10)
        }
        .sheet(isPresented: $showPassengerSelector) {
            PassengersAndClassSelector(
                adultsCount: $adultsCount,
                childrenCount: $childrenCount,
                selectedClass: $selectedCabinClass, // FIXED: Use selectedCabinClass instead of selectedClass
                childrenAges: $childrenAges
            )
            .presentationDetents([.fraction(0.9), .large]) // ADDED: Custom sheet sizes
            .presentationDragIndicator(.visible) // ADDED: Drag indicator
        }
    }
}

#Preview {
    FAheader()
}
