import SwiftUI

struct WaitView: View {
    @State private var spin = false
    @State private var phase: CGFloat = 0
    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(red: 0.04, green: 0.17, blue: 0.36), Color(red: 0.01, green: 0.06, blue: 0.16)],
                           center: .top, startRadius: 20, endRadius: 600).ignoresSafeArea()
            VStack(spacing: 8) {
                Image("LogoRuha").resizable().scaledToFit().frame(width: 230)
                    .rotation3DEffect(.degrees(spin ? 18 : -18), axis: (0, 1, 0))
                    .shadow(color: Theme.ocean.opacity(0.6), radius: 24)
                    .padding(.bottom, 14)
                Text("Yayın yeniden bağlanıyor…").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.tq)
                Text("Lütfen bekleyin").font(.system(size: 13)).foregroundColor(Theme.muted)
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Circle().fill(Theme.tq).frame(width: 9, height: 9)
                            .opacity(phase == CGFloat(i) ? 1 : 0.35)
                    }
                }.padding(.top, 10)
            }
            VStack { Spacer(); Waves().frame(height: 100) }.ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { spin = true }
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in phase = (phase + 1).truncatingRemainder(dividingBy: 3) }
        }
    }
}

struct Waves: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                wave(t * 0.9, 0, Theme.tq.opacity(0.2))
                wave(-t * 0.6, 1.7, Theme.ocean.opacity(0.22))
                wave(t * 0.4, 3.4, Color(red: 0.08, green: 0.4, blue: 0.75).opacity(0.28))
            }
        }
    }
    func wave(_ s: Double, _ ph: Double, _ c: Color) -> some View {
        GeometryReader { g in
            Path { p in
                let w = g.size.width, h = g.size.height
                p.move(to: CGPoint(x: 0, y: h))
                var x: CGFloat = 0
                while x <= w {
                    let y = h * 0.45 + sin(Double(x) / w * 6.0 + s + ph) * h * 0.14
                    p.addLine(to: CGPoint(x: x, y: CGFloat(y)))
                    x += 4
                }
                p.addLine(to: CGPoint(x: w, y: h))
                p.closeSubpath()
            }.fill(c)
        }
    }
}

struct SplashView: View {
    @ObservedObject var cfg: RemoteConfig
    @State private var progress: CGFloat = 0
    var body: some View {
        ZStack {
            Theme.night.ignoresSafeArea()
            GeometryReader { g in
                Group {
                    if let img = cfg.splashImage { Image(uiImage: img).resizable() } else { Image("Splash").resizable() }
                }
                .scaledToFill().frame(width: g.size.width, height: g.size.height).clipped()
            }.ignoresSafeArea()
            VStack(spacing: 10) {
                Spacer()
                Text("Yayın hazırlanıyor…").font(.system(size: 16)).foregroundColor(Theme.tq)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    GeometryReader { g in Capsule().fill(Theme.gradient).frame(width: g.size.width * progress) }
                }.frame(width: 300, height: 6)
            }.padding(.bottom, 40)
        }
        .onAppear { withAnimation(.linear(duration: 6)) { progress = 1 } }
    }
}
