import SwiftUI

struct LocationItem: View {
    let icon: String
    let code: String
    let city: String
    let showRemoveButton: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                HStack() {
                    Text(code)
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(city)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                if showRemoveButton {
                    Text("Remove")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.white)
        }
    }
}
