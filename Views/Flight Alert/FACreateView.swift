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
                HStack{
                    HStack{
                        HStack{
                            Image("FAex")
                                .frame(width: 16, height: 16)
                            Text("What is alert?")
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(Color("FABlue"))
                        }
                        .padding(.horizontal)
                        .padding(.vertical,10)
                        .background(Color("FABlue").opacity(0.1))
                        .cornerRadius(30)
                        
                        Spacer()
                    }
//                    .padding()
                    
                }
                .padding(.horizontal)
                
                Spacer()
                Image("FALogoBlue")
                    .frame(width: 236, height: 120)
                Text("Login to get access to the latest price drops on return flights")
                    .padding(.horizontal, 40)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Spacer()
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
                .padding(.vertical)
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
