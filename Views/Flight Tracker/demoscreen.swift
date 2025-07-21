import SwiftUI

struct demoscreen : View {
    var body: some View {
        HStack(spacing: 0) {
            // Left circle
            Circle()
                .stroke(Color.black.opacity(0.6), lineWidth: 1)
                .frame(width: 6, height: 6) // Reduced from 6 to 5
            
            // Left line segment
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width:12,height: 1)
               
            
            // Date/Time capsule in the middle
            Text("duration")
                .font(.system(size: 11)) // Reduced from 12 to 11
                .foregroundColor(Color.black.opacity(0.6))
                .padding(.horizontal, 10) // Reduced from 8 to 6
                .padding(.vertical, 1) // Reduced from 2 to 1
                .background(
                    Capsule()
                        .fill(Color.white)
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal,6)
            
            // Right line segment
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width:12,height: 1)
                
            
            // Right circle
            Circle()
                .stroke(Color.black.opacity(0.6), lineWidth: 1)
                .frame(width: 6, height: 6) // Reduced from 6 to 5
        }
        .frame(width: 116)
    }
}


#Preview {
    demoscreen()
}
