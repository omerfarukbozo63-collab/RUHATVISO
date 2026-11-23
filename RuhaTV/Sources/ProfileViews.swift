import SwiftUI

/// Acilista cikan profil secimi: Ruha TV / Radyo Ruha
struct ProfilePickerView: View {
    @ObservedObject var cfg: RemoteConfig
    let pick: (Int) -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.15, blue: 0.31), Theme.night, Color(red: 0.01, green: 0.03, blue: 0.09)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 6) {
                Text("Hoş geldiniz").font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                Text("Bir profil seçin").font(.system(size: 15)).foregroundColor(Theme.tq).padding(.bottom, 14)
                HStack(spacing: 24) {
                    card(name: "Ruha TV", sub: "Canlı televizyon yayını") {
                        Image("LogoRuha").resizable().scaledToFit()
                    } action: { pick(0) }
                    card(name: "Radyo Ruha", sub: "Canlı radyo yayını") {
                        if let img = cfg.radioLogo {
                            Image(uiImage: img).resizable().scaledToFit()
                        } else {
                            Text("RADYO\nRUHA").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.tq)
                                .multilineTextAlignment(.center)
                        }
                    } action: { pick(1) }
                }
            }
        }
    }

    func card<L: View>(name: String, sub: String, @ViewBuilder logo: () -> L, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                logo().frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 10)
                Text(name).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(sub).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            .padding(16).frame(width: 200, height: 190)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// Radyo modunda goruntu yerine gorunen ekran
struct RadioScreen: View {
    @ObservedObject var cfg: RemoteConfig
    @State private var pulse = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.17, blue: 0.36), Theme.night, Color(red: 0.01, green: 0.03, blue: 0.09)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 18) {
                if let img = cfg.radioLogo {
                    Image(uiImage: img).resizable().scaledToFit().frame(width: 260, height: 130)
                        .shadow(color: Theme.ocean.opacity(0.5), radius: 20)
                } else {
                    Text("RADYO RUHA").font(.system(size: 30, weight: .bold)).foregroundColor(Theme.tq)
                }
                Text("●  CANLI RADYO YAYINI").font(.system(size: 13, weight: .bold)).tracking(2.5)
                    .foregroundColor(Theme.tq).opacity(pulse ? 1 : 0.45)
            }
            VStack { Spacer(); Waves().frame(height: 110) }.ignoresSafeArea()
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true } }
    }
}
