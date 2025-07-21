import SwiftUI
import UIKit

struct SearchInput: View {
    @StateObject private var viewModel = SearchViewModel()
    @Namespace private var animation
    
    // State to control bottom sheets
    @State private var showPassengersAndClassSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Trip type selector
            TripTypeSelector(viewModel: viewModel, namespace: animation)
            
            // Selected trip view
            ZStack {
                if viewModel.tripType == .multiCity {
                    MultiCityView(viewModel: viewModel)
                        .transition(.opacity)
                } else {
                    SingleTripView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.tripType)
            
            Divider().padding(.leading, 50)
            
            // Passenger and class selector - Tappable to open bottom sheet
            HStack {
                Image("profileIcon")
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                Text("\(viewModel.adultsCount) Adult\(viewModel.adultsCount > 1 ? "s" : "")\(viewModel.childrenCount > 0 ? ", \(viewModel.childrenCount) Child\(viewModel.childrenCount > 1 ? "ren" : "")" : "") - \(viewModel.travelClass.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.selectionFeedback() // Added haptic feedback
                showPassengersAndClassSheet = true
            }
            
            Spacer()
            
            // Search button
            Button(action: {
                HapticManager.shared.impactFeedback(style: .medium) // Added haptic feedback
                viewModel.search()
            }) {
                Text("Search Flights")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppSecondaryColor"))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 15)
            
            // Direct flights toggle with haptic feedback
            HStack {
                Text("Direct flights only")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
                
                Toggle("", isOn: $viewModel.directFlightsOnly.onChange { _ in
                    HapticManager.shared.impactFeedback(style: .light) // Added haptic feedback for toggle
                })
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.8)
                
                Spacer()
            }
            .padding()
            .padding(.horizontal, 5)
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange, lineWidth: 1)
        )
        .padding()
        // Location sheet
        .sheet(isPresented: $viewModel.isLocationSheetOpen) {
            LocationSheet(
                isOrigin: viewModel.isEditingOrigin,
                onLocationSelected: { location in
                    HapticManager.shared.selectionFeedback() // Added haptic feedback
                    viewModel.handleLocationSelection(location)
                }
            )
        }
        // Passengers and Class bottom sheet
        .sheet(isPresented: $showPassengersAndClassSheet) {
//            PassengersAndClassSelector(viewModel: viewModel)
//                .edgesIgnoringSafeArea(.all)
        }
        // Add animation modifier to the entire view
        .animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0.1), value: viewModel.tripType)
    }
}

// Extension to add onChange to Binding
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// Singleton class to manage haptic feedback
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Impact feedback for buttons and toggles
    func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Selection feedback for when something is selected
    func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // Notification feedback for success, warning, or errors
    func notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// Preview
struct SearchInput_Previews: PreviewProvider {
    static var previews: some View {
        SearchInput()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.blue.opacity(0.1))
    }
}

// Preview
//struct SearchInput_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchInput()
//            .previewLayout(.sizeThatFits)
//            .padding()
//            .background(Color.blue.opacity(0.1))
//    }
//}
