import Foundation

struct NewsItem: Identifiable {
    let id = UUID()
    var title = ""
    var link = ""
    var category = ""
    var image = ""
    var date: Date?

    var timeAgo: String {
        guard let date = date else { return "" }
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "az önce" }
        if s < 3600 { return "\(s / 60) dk önce" }
        if s < 86400 { return "\(s / 3600) sa önce" }
        if s < 172800 { return "dün" }
        return "\(s / 86400) gün önce"
    }
}

/// urfahaber.com/rss.xml okuyucu
final class NewsFeed: NSObject, ObservableObject, XMLParserDelegate {
    static let url = URL(string: "https://www.urfahaber.com/rss.xml")!
    @Published var items: [NewsItem] = []

    private var parsed: [NewsItem] = []
    private var cur: NewsItem?
    private var text = ""
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    func refresh() async {
        var req = URLRequest(url: Self.url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
        let list = await MainActor.run { () -> [NewsItem] in
            parsed = []; cur = nil
            let p = XMLParser(data: data)
            p.delegate = self
            p.parse()
            return Array(parsed.prefix(20))
        }
        if !list.isEmpty { await MainActor.run { items = list } }
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String] = [:]) {
        text = ""
        if name == "item" { cur = NewsItem() }
        guard cur != nil else { return }
        if (name == "enclosure" || name == "media:content" || name == "media:thumbnail"),
           cur?.image.isEmpty == true, let u = a["url"] { cur?.image = u }
    }

    func parser(_ parser: XMLParser, foundCharacters s: String) { text += s }
    func parser(_ parser: XMLParser, foundCDATA b: Data) { text += String(data: b, encoding: .utf8) ?? "" }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        guard cur != nil else { return }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch name {
        case "title": cur?.title = t
        case "link": cur?.link = t
        case "category": if cur?.category.isEmpty == true { cur?.category = t }
        case "pubDate": cur?.date = Self.df.date(from: t)
        case "item":
            if let c = cur, !c.title.isEmpty { parsed.append(c) }
            cur = nil
        default: break
        }
    }
}
