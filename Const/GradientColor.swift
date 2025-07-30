

import SwiftUI

struct GradientColor {
    
    static let Primary = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#141738"),
                    Color(hex: "#121965")
                ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let Secondary = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#FE6439"),
                    Color(hex: "#F92E12")
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let SplashGradient = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#FF5F30"),
                    Color(hex: "#DA1010")
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BlueWhite = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#0C243E"),
                    Color(hex: "#F4F6F8"),
                    Color(hex: "#F4F6F8"),
                    Color(hex: "#F4F6F8"),
                    Color(hex: "#F4F6F8")
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let DeleteRed = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#CC142B"),
            Color(hex: "#DF001C")
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let transparentWhite = LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white, Color.white]),
            startPoint: .top,
            endPoint: .bottom
        )
    
 
    
    static let FTHGradient = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#02060C"),
                    Color(hex: "#0C243E").opacity(0.7),
                    Color(hex: "#0C243E").opacity(0.1),
                    Color(hex: "#0C243E").opacity(0.1),
                    Color(hex: "#0C243E").opacity(0.1),
                    Color(hex: "#0C243E").opacity(0.1),
                    Color(hex: "#0C243E").opacity(0)
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    
}
