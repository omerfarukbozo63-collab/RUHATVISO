import SwiftUI
import AVKit

enum Panel { case none, news, info, social }

struct ContentView: View {
    @StateObject private var cfg = RemoteConfig()
    @StateObject private var model = PlayerModel()
    @StateObject private var feed = NewsFeed()
    @State private var splash = true
    @State private var profile: Int? = nil     // nil: secilmedi, 0: Ruha TV, 1: Radyo Ruha
    @State private var controls = false
    @State private var panel: Panel = .none
    @State private var tickerIdx = 0
    @State private var tickerProg: CGFloat = 0
    @State private var hideTask: DispatchWorkItem?
    @State private var aspectMenu = false
    @Environment(\.scenePhase) private var scenePhase

    private let tick = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PlayerSurface(model: model).ignoresSafeArea()
                .onTapGesture { toggleControls() }

            if profile == 1 { RadioScreen(cfg: cfg).onTapGesture { toggleControls() } }

            if model.waiting { WaitView().transition(.opacity) }

            if controls && panel == .none { controlsLayer.transition(.opacity) }

            if panel != .none {
                Color.black.opacity(0.55).ignoresSafeArea().onTapGesture { close() }.transition(.opacity)
            }
            switch panel {
            case .news:
                VStack { Spacer(); NewsPanel(feed: feed, close: close) }.ignoresSafeArea(edges: .bottom).transition(.move(edge: .bottom))
            case .info: InfoPanel(cfg: cfg, close: close).transition(.opacity)
            case .social: SocialPanel(cfg: cfg, close: close).transition(.opacity)
            case .none: EmptyView()
            }

            if profile == nil && !splash { ProfilePickerView(cfg: cfg, pick: choose).transition(.opacity).zIndex(9) }
            if splash { SplashView(cfg: cfg).transition(.opacity).zIndex(10) }
        }
        .gesture(DragGesture(minimumDistance: 40).onEnded { v in
            if panel == .none, !splash, profile != nil, v.translation.height < -70, abs(v.translation.height) > abs(v.translation.width) * 1.5 {
                open(.news)
            }
        })
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            async let a: Void = cfg.refresh()
            async let b: Void = feed.refresh()
            _ = await (a, b)
        }
        .onChange(of: cfg.streamURL) { if profile == 0 { model.play($0) } }
        .onChange(of: cfg.radioURL) { if profile == 1, let u = $0 { model.play(u) } }
        .onReceive(tick) { _ in stepTicker() }
        .onChange(of: scenePhase) { if $0 == .active { model.resume(); Task { await feed.refresh() } } }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { withAnimation(.easeOut(duration: 0.8)) { splash = false } }
        }
    }

    // MARK: kontroller
    var controlsLayer: some View {
        ZStack {
            // Sag: cam kontrol cubugu
            VStack(spacing: 6) {
                dockButton("arrow.triangle.2.circlepath") { switchProfile() }
                if profile != 1 { dockButton("rectangle.inset.filled.and.person.filled") { model.startPip() } }
                dockButton("heart") { open(.social) }
                dockButton("info.circle") { open(.info) }
                Divider().background(Color.white.opacity(0.15)).padding(.horizontal, 8)
                dockButton(model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill", on: model.muted) { model.toggleMute(); scheduleHide() }
            }
            .padding(7).glass(26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)

            // Sol alt: goruntu orani
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                if aspectMenu && profile != 1 {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<PlayerModel.aspectNames.count, id: \.self) { i in
                            Button { model.aspect = i; aspectMenu = false; scheduleHide() } label: {
                                Text(PlayerModel.aspectNames[i]).font(.system(size: 14, weight: model.aspect == i ? .bold : .regular))
                                    .foregroundColor(model.aspect == i ? Theme.tq : .white)
                                    .frame(width: 100, height: 38)
                            }
                        }
                    }.glass(16)
                }
                if profile != 1 { Button { aspectMenu.toggle(); scheduleHide() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 13))
                        Text(PlayerModel.aspectNames[model.aspect] + " ▾").font(.system(size: 14, weight: .bold))
                    }.foregroundColor(.white).padding(.horizontal, 16).frame(height: 40).glass(20)
                } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(14)

            // Alt: son haber bandi
            VStack {
                Spacer()
                tickerBar.padding(.leading, 124).padding(.trailing, 70).padding(.bottom, 14)
            }
        }
    }

    func dockButton(_ icon: String, on: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundColor(on ? Theme.night : .white)
                .frame(width: 40, height: 40)
                .background(on ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Color.white.opacity(0.08)), in: Circle())
        }
    }

    var tickerTitle: String {
        feed.items.isEmpty ? "Urfa Haber — son haberler için dokunun" : feed.items[tickerIdx % feed.items.count].title
    }

    var tickerBar: some View {
        Button { open(.news) } label: {
            HStack(spacing: 12) {
                Image("LogoUrfa").resizable().scaledToFit().frame(width: 64, height: 28)
                    .padding(.horizontal, 10).frame(height: 40)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("●  SON HABER").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundColor(Theme.tq)
                    Text(tickerTitle).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                        .id(tickerIdx).transition(.opacity)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.night)
                    .frame(width: 36, height: 36).background(Theme.gradient, in: Circle())
            }
            .padding(.horizontal, 9).frame(height: 58).glass(20)
            .overlay(alignment: .bottomLeading) {
                GeometryReader { g in Rectangle().fill(Theme.gradient).frame(width: g.size.width * tickerProg, height: 3) }
                    .frame(height: 3).clipShape(RoundedRectangle(cornerRadius: 20)).frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .buttonStyle(.plain)
        .onAppear { restartProgress() }
    }

    // MARK: davranis
    func stepTicker() {
        guard feed.items.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { tickerIdx = (tickerIdx + 1) % feed.items.count }
        restartProgress()
    }

    func restartProgress() {
        tickerProg = 0
        withAnimation(.linear(duration: 6)) { tickerProg = 1 }
    }

    func toggleControls() {
        guard !splash, profile != nil else { return }
        if aspectMenu { aspectMenu = false; return }
        withAnimation(.easeInOut(duration: 0.2)) { controls.toggle() }
        if controls { scheduleHide() }
    }

    func scheduleHide() {
        hideTask?.cancel()
        let w = DispatchWorkItem { withAnimation { controls = false; aspectMenu = false } }
        hideTask = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: w)
    }

    func open(_ p: Panel) {
        hideTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) { controls = false; aspectMenu = false; panel = p }
        if p == .news { Task { await feed.refresh() } }
    }

    func choose(_ p: Int) {
        withAnimation(.easeOut(duration: 0.3)) { profile = p }
        model.nowTitle = p == 1 ? "Radyo Ruha" : "Ruha TV"
        if p == 1 {
            if let u = cfg.radioURL { model.play(u) }
        } else {
            model.play(cfg.streamURL)
        }
    }

    func switchProfile() {
        model.stop()
        withAnimation { controls = false; aspectMenu = false; profile = nil }
    }

    func close() { withAnimation(.easeIn(duration: 0.22)) { panel = .none } }
}
