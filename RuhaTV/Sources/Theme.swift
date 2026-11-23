import SwiftUI

enum Theme {
    static let tq = Color(red: 0.114, green: 0.914, blue: 0.816)      // #1DE9D0
    static let ocean = Color(red: 0.039, green: 0.604, blue: 0.839)   // #0A9AD6
    static let night = Color(red: 0.016, green: 0.067, blue: 0.165)   // #04112A
    static let deep = Color(red: 0.031, green: 0.122, blue: 0.271)    // #081F45
    static let muted = Color(red: 0.616, green: 0.706, blue: 0.792)   // #9DB4CA
    static let gradient = LinearGradient(colors: [tq, ocean], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct Glass: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(Theme.night.opacity(0.45), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.17), lineWidth: 1))
    }
}

extension View {
    func glass(_ radius: CGFloat = 20) -> some View { modifier(Glass(radius: radius)) }
}

struct PanelCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(LinearGradient(colors: [Color(red: 0.04, green: 0.15, blue: 0.31), Theme.night],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.tq.opacity(0.7), lineWidth: 1.5))
    }
}

extension View {
    func panelCard() -> some View { modifier(PanelCard()) }
}

struct CloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.09), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
    }
}
