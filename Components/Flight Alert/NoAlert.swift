import SwiftUI

struct NoAlert: View {
    var body: some View {
        VStack(spacing:20){
            Text("There are no price drop from these location right now")
                .font(.system(size: 20))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal,50)
            Text("Try another departure city")
        }
    }
}


#Preview {
    NoAlert()
}
