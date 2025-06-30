import SwiftUI

struct FACreate: View {
    @State private var showLocationSheet = false
    
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
                FALocationSheet()
            }

            Spacer()
        }
            }
}

#Preview {
    FACreate()
}
