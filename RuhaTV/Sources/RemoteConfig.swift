import Foundation
import SwiftUI

struct SocialItem: Identifiable {
    let id = UUID()
    let name: String
    let handle: String
    let platform: String
    let url: URL
}

/// Gist'ten uzaktan gelen ayarlar: yayin linki, bilgi metni, sosyal liste, acilis gorseli.
final class RemoteConfig: ObservableObject {
    static let defaultStream = "http://163.172.31.106:8080/memfs/f7ba0b87-af81-491c-ba90-cb3fb6f15314.m3u8"
    static let base = "https://ruhatv.com.tr/"
    static let streamCfg = base + "yayin.txt"
    static let radioCfg = base + "radyoruha.txt"
    static let radioLogoCfg = base + "radyoruhalogo.txt"
    static let socialCfg = base + "sosyal.txt"
    static let infoCfg = base + "bilgi.txt"
    static let splashCfg = base + "acilis.txt"

    @Published var streamURL: URL
    @Published var radioURL: URL?
    @Published var radioLogo: UIImage?
    @Published var infoTitle: String
    @Published var infoBody: String
    @Published var social: [SocialItem]
    @Published var splashImage: UIImage?

    private let d = UserDefaults.standard
    private let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        c.timeoutIntervalForRequest = 8
        return URLSession(configuration: c)
    }()

    init() {
        streamURL = URL(string: d.string(forKey: "stream") ?? Self.defaultStream) ?? URL(string: Self.defaultStream)!
        radioURL = d.string(forKey: "radio").flatMap { URL(string: $0) }
        infoTitle = d.string(forKey: "infoTitle") ?? "Genel Bilgi"
        infoBody = d.string(forKey: "infoBody") ?? "Ruha TV'ye hoş geldiniz."
        social = RemoteConfig.parseSocial(d.string(forKey: "social") ?? "")
        if social.isEmpty { social = RemoteConfig.defaultSocial }
        if let data = try? Data(contentsOf: RemoteConfig.splashFile), let img = UIImage(data: data) { splashImage = img }
        if let data = try? Data(contentsOf: RemoteConfig.radioLogoFile), let img = UIImage(data: data) { radioLogo = img }
    }

    static var splashFile: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("acilis.img")
    }

    static var radioLogoFile: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("radyo_logo.img")
    }

    static let defaultSocial: [SocialItem] = [
        ("Ruha TV", "@ruhatv", "Instagram", "https://www.instagram.com/ruhatv"),
        ("Urfa Haber", "@urfa_haber", "Instagram", "https://www.instagram.com/urfa_haber"),
        ("Ruha TV", "Ruhatv1", "YouTube", "https://www.youtube.com/user/Ruhatv1"),
    ].compactMap { t in URL(string: t.3).map { SocialItem(name: t.0, handle: t.1, platform: t.2, url: $0) } }

    private func fetch(_ s: String) async -> String? {
        guard let u = URL(string: s) else { return nil }
        do {
            let (data, resp) = try await session.data(from: u)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }

    private func firstLine(_ t: String) -> String? {
        for l in t.replacingOccurrences(of: "\u{FEFF}", with: "").components(separatedBy: .newlines) {
            let x = l.trimmingCharacters(in: .whitespaces)
            if !x.isEmpty { return x }
        }
        return nil
    }

    func refresh() async {
        if let t = await fetch(Self.streamCfg), let l = firstLine(t), l.hasPrefix("http"), let u = URL(string: l) {
            d.set(l, forKey: "stream")
            await MainActor.run { if u != streamURL { streamURL = u } }
        }
        if let t = await fetch(Self.radioCfg), let l = firstLine(t), l.hasPrefix("http"), let u = URL(string: l) {
            d.set(l, forKey: "radio")
            await MainActor.run { if u != radioURL { radioURL = u } }
        }
        if let t = await fetch(Self.radioLogoCfg), var l = firstLine(t), l.hasPrefix("http") {
            if l.contains("github.com") && l.contains("/blob/") {
                l = l.replacingOccurrences(of: "github.com", with: "raw.githubusercontent.com")
                    .replacingOccurrences(of: "/blob/", with: "/")
            }
            if let u = URL(string: l), l != d.string(forKey: "radioLogoURL") || radioLogo == nil,
               let (data, resp) = try? await session.data(from: u),
               (resp as? HTTPURLResponse)?.statusCode == 200, data.count < 8_000_000,
               let img = UIImage(data: data) {
                try? data.write(to: Self.radioLogoFile)
                d.set(l, forKey: "radioLogoURL")
                await MainActor.run { radioLogo = img }
            }
        }
        if let t = await fetch(Self.infoCfg) {
            let lines = t.replacingOccurrences(of: "\u{FEFF}", with: "").components(separatedBy: "\n")
            if let i = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                let title = lines[i].trimmingCharacters(in: .whitespaces)
                let body = lines[(i + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                d.set(title, forKey: "infoTitle"); d.set(body, forKey: "infoBody")
                await MainActor.run { infoTitle = title; infoBody = body }
            }
        }
        if let t = await fetch(Self.socialCfg) {
            let items = Self.parseSocial(t)
            if !items.isEmpty {
                d.set(t, forKey: "social")
                await MainActor.run { social = items }
            }
        }
        if let t = await fetch(Self.splashCfg), var l = firstLine(t), l.hasPrefix("http") {
            if l.contains("github.com") && l.contains("/blob/") {
                l = l.replacingOccurrences(of: "github.com", with: "raw.githubusercontent.com")
                    .replacingOccurrences(of: "/blob/", with: "/")
            }
            if l != d.string(forKey: "splashURL"), let u = URL(string: l),
               let (data, resp) = try? await session.data(from: u),
               (resp as? HTTPURLResponse)?.statusCode == 200, data.count < 8_000_000,
               let img = UIImage(data: data) {
                try? data.write(to: Self.splashFile)
                d.set(l, forKey: "splashURL")
                await MainActor.run { splashImage = img }
            }
        }
    }

    // "Isim | @kullanici | Platform | link"  ya da sadece "link"
    static func parseSocial(_ text: String) -> [SocialItem] {
        var out: [SocialItem] = []
        for raw in text.replacingOccurrences(of: "\u{FEFF}", with: "").components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let last = parts.last, last.hasPrefix("http"), let url = URL(string: last) else { continue }
            if parts.count >= 4 {
                out.append(SocialItem(name: parts[0], handle: parts[1], platform: parts[2], url: url))
            } else {
                let host = (url.host ?? "").replacingOccurrences(of: "www.", with: "")
                let tail = url.pathComponents.last(where: { $0 != "/" }) ?? ""
                let plat = host.hasPrefix("instagram") ? "Instagram" : (host.hasPrefix("x.com") || host.hasPrefix("twitter")) ? "X"
                    : host.hasPrefix("youtube") ? "YouTube" : host.hasPrefix("facebook") ? "Facebook" : "Web"
                out.append(SocialItem(name: tail.isEmpty ? host : tail, handle: tail.isEmpty ? host : "@" + tail, platform: plat, url: url))
            }
            if out.count >= 12 { break }
        }
        return out
    }
}
