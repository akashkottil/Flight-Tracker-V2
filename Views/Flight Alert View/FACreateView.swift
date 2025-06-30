import SwiftUI

// MARK: - FACreateView (Main Entry Point)

struct FACreateView: View {
    // ADDED: Callback for when alert is created
    let onAlertCreated: ((AlertResponse) -> Void)?
    
    // ADDED: Default initializer for backward compatibility
    init(onAlertCreated: ((AlertResponse) -> Void)? = nil) {
        self.onAlertCreated = onAlertCreated
    }
    
    var body: some View {
        // UPDATED: Pass callback to FACreate
        FACreate(onAlertCreated: onAlertCreated)
    }
}

// MARK: - FACreate Component (Implementation)

struct FACreate: View {
    @State private var showLocationSheet = false
    
    // ADDED: Callback for alert creation
    let onAlertCreated: ((AlertResponse) -> Void)?
    
    // ADDED: Default initializer for backward compatibility
    init(onAlertCreated: ((AlertResponse) -> Void)? = nil) {
        self.onAlertCreated = onAlertCreated
    }
    
    var body: some View {
        VStack{
            Spacer()
            VStack(spacing: 30) {
                Image("FALogoBlue")
                Text("Let us know your departure airports. we'll customize the best flight deals for you!")
                    .padding(.horizontal, 40)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button(action: {
                    showLocationSheet = true
                }) {
                    Text("Pick departure city")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("FABlue"))
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 4)
                }
                .padding(.horizontal, 30)
            }
            .sheet(isPresented: $showLocationSheet) {
                // UPDATED: Pass the callback to FALocationSheet
                FALocationSheet(onAlertCreated: onAlertCreated)
            }

            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("FACreateView") {
    FACreateView()
}

#Preview("FACreate") {
    FACreate()
}
