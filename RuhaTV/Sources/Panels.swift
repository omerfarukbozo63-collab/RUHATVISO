import SwiftUI

// MARK: Haber paneli (alttan)
struct NewsPanel: View {
    @ObservedObject var feed: NewsFeed
    let close: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.white.opacity(0.35)).frame(width: 44, height: 5).padding(.top, 8)
            HStack(spacing: 12) {
                Image("LogoUrfa").resizable().scaledToFit().frame(width: 62, height: 28)
                    .padding(.horizontal, 11).padding(.vertical, 6)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Son Haberler").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("urfahaber.com").font(.system(size: 12)).foregroundColor(Theme.tq)
                }
                Spacer()
                Button { openURL(URL(string: "https://www.urfahaber.com")!) } label: {
                    Text("Siteyi aç  ↗").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 14).frame(height: 34).glass(17)
                }
                CloseButton(action: close)
            }
            .padding(.horizontal, 18).padding(.top, 10)

            if feed.items.isEmpty {
                Text("Haberler yükleniyor…").foregroundColor(Theme.muted).padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(feed.items.enumerated()), id: \.element.id) { i, n in
                            NewsCard(item: n, featured: i == 0).onTapGesture {
                                if let u = URL(string: n.link) { openURL(u) }
                            }
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                }
            }
        }
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [Theme.deep, Theme.night], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))
        )
        .overlay(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]).stroke(Theme.tq.opacity(0.7), lineWidth: 1.5))
    }
}

struct NewsCard: View {
    let item: NewsItem
    let featured: Bool
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Theme.deep
            AsyncImage(url: URL(string: item.image)) { ph in
                if let img = ph.image { img.resizable().scaledToFill() } else { Color.clear }
            }
            LinearGradient(colors: [.clear, .clear, Theme.night.opacity(0.94)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.system(size: 13.5, weight: .bold)).foregroundColor(.white)
                    .lineLimit(3).multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text(item.timeAgo).font(.system(size: 10.5))
                }.foregroundColor(Theme.muted)
            }
            .padding(12)
            if !item.category.isEmpty {
                Text(item.category.uppercased()).font(.system(size: 9.5, weight: .bold)).tracking(0.8)
                    .foregroundColor(Theme.tq).padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Theme.night.opacity(0.72), in: Capsule())
                    .overlay(Capsule().stroke(Theme.tq.opacity(0.55), lineWidth: 1))
                    .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 232, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(featured ? Theme.tq : Color.white.opacity(0.12), lineWidth: featured ? 2 : 1))
        .shadow(color: featured ? Theme.tq.opacity(0.35) : .clear, radius: 12)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// MARK: Bilgi ekrani
struct InfoPanel: View {
    @ObservedObject var cfg: RemoteConfig
    let close: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Image("LogoRuha").resizable().scaledToFit().frame(height: 36)
                Text(cfg.infoTitle).font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                Capsule().fill(Theme.gradient).frame(width: 74, height: 3).padding(.bottom, 4)
                ScrollView {
                    Text(cfg.infoBody).font(.system(size: 17)).foregroundColor(Color(red: 0.86, green: 0.91, blue: 0.96))
                        .lineSpacing(5).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            CloseButton(action: close).padding(14)
        }
        .panelCard()
        .padding(.horizontal, 40).padding(.vertical, 24)
        .shadow(color: Theme.tq.opacity(0.18), radius: 30)
    }
}

// MARK: Sosyal medya paneli
struct SocialPanel: View {
    @ObservedObject var cfg: RemoteConfig
    let close: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                HStack { Image("LogoRuha").resizable().scaledToFit().frame(height: 24); Spacer(); CloseButton(action: close) }
                VStack(spacing: 2) {
                    Text("♡  Bizi Takip Edin").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    Text("Bir hesaba dokunun, bizi takip edin").font(.system(size: 12)).foregroundColor(Theme.muted)
                }
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(Array(cfg.social.enumerated()), id: \.element.id) { i, s in
                        Button { openURL(s.url) } label: { tile(s, featured: i == 0) }
                    }
                }.padding(.vertical, 4)
            }
            Text("Panel 10 saniye sonra kendiliğinden kapanır").font(.system(size: 11)).foregroundColor(Color(white: 0.55))
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(Theme.gradient).frame(width: g.size.width * progress)
                }
            }.frame(height: 5)
        }
        .padding(20)
        .panelCard()
        .padding(.horizontal, 30).padding(.vertical, 14)
        .onAppear {
            progress = 1
            withAnimation(.linear(duration: 10)) { progress = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { close() }
        }
    }

    func tile(_ s: SocialItem, featured: Bool) -> some View {
        HStack(spacing: 10) {
            SocialIcon(platform: s.platform).frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.name).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                Text(s.handle).font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(1)
                Text(s.platform.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.8)
                    .foregroundColor(Theme.tq).padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(featured ? Theme.tq.opacity(0.18) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(featured ? Theme.tq : Color.white.opacity(0.14), lineWidth: featured ? 2 : 1))
    }
}

struct SocialIcon: View {
    let platform: String
    var body: some View {
        let p = platform.lowercased()
        ZStack {
            if p.contains("insta") {
                RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.4), Color(red: 0.99, green: 0.35, blue: 0.29), Color(red: 0.84, green: 0.14, blue: 0.62), Color(red: 0.16, green: 0.35, blue: 0.92)], startPoint: .bottomLeading, endPoint: .topTrailing))
                RoundedRectangle(cornerRadius: 7).stroke(Color.white, lineWidth: 2.4).padding(8)
                Circle().stroke(Color.white, lineWidth: 2.4).padding(13)
            } else if p == "x" || p.contains("twitter") {
                RoundedRectangle(cornerRadius: 10).fill(Color.black)
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1)
                Text("𝕏").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            } else if p.contains("youtube") {
                RoundedRectangle(cornerRadius: 9).fill(Color.red).padding(.vertical, 6)
                Image(systemName: "play.fill").foregroundColor(.white).font(.system(size: 14))
            } else if p.contains("facebook") {
                Circle().fill(Color(red: 0.09, green: 0.47, blue: 0.95))
                Text("f").font(.system(size: 26, weight: .bold)).foregroundColor(.white).offset(y: 2)
            } else {
                Circle().fill(Theme.gradient)
                Image(systemName: "globe").foregroundColor(Theme.night)
            }
        }
    }
}
