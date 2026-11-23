import AVKit
import SwiftUI
import Combine
import MediaPlayer

/// Yayin oynatici: otomatik baslar, kopunca yeniden baglanir, 4 sn takilirsa bekleme ekrani cikar.
final class PlayerModel: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    let player = AVPlayer()
    @Published var waiting = false
    @Published var muted = false
    @Published var aspect = 0          // 0 sigdir, 1 doldur, 2 uzat
    var pip: AVPictureInPictureController?
    var nowTitle = "Ruha TV"
    private var url: URL?
    private var bag = Set<AnyCancellable>()
    private var waitTimer: Timer?
    private var retryTimer: Timer?

    static let aspectNames = ["Sığdır", "Doldur", "Uzat"]
    var gravity: AVLayerVideoGravity { aspect == 1 ? .resizeAspectFill : aspect == 2 ? .resize : .resizeAspect }

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.automaticallyWaitsToMinimizeStalling = true
        player.publisher(for: \.timeControlStatus).receive(on: DispatchQueue.main).sink { [weak self] st in
            self?.statusChanged(st)
        }.store(in: &bag)
        let rc = MPRemoteCommandCenter.shared()
        rc.playCommand.addTarget { [weak self] _ in self?.player.play(); return .success }
        rc.pauseCommand.addTarget { [weak self] _ in self?.player.pause(); return .success }
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in self?.scheduleRetry() }.store(in: &bag)
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in self?.scheduleRetry() }.store(in: &bag)
    }

    func play(_ u: URL) {
        url = u
        let item = AVPlayerItem(url: u)
        player.replaceCurrentItem(with: item)
        player.isMuted = muted
        player.play()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: nowTitle,
            MPMediaItemPropertyArtist: "Ruha TV",
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]
        item.publisher(for: \.status).receive(on: DispatchQueue.main).sink { [weak self] s in
            if s == .failed { self?.scheduleRetry() }
        }.store(in: &bag)
    }

    func resume() { if url != nil { player.play() } }

    func stop() {
        waitTimer?.invalidate(); waitTimer = nil
        retryTimer?.invalidate(); retryTimer = nil
        url = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        waiting = false
    }

    func toggleMute() { muted.toggle(); player.isMuted = muted }

    private func statusChanged(_ st: AVPlayer.TimeControlStatus) {
        if st == .playing {
            waitTimer?.invalidate(); waitTimer = nil
            retryTimer?.invalidate(); retryTimer = nil
            if waiting { withAnimation(.easeOut(duration: 0.4)) { waiting = false } }
        } else if st == .waitingToPlayAtSpecifiedRate, waitTimer == nil, !waiting {
            waitTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                withAnimation { self.waiting = true }
                self.waitTimer = nil
            }
        }
    }

    private func scheduleRetry() {
        guard retryTimer == nil else { return }
        withAnimation { waiting = true }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            guard let self = self, let u = self.url else { return }
            self.retryTimer = nil
            self.play(u)
        }
    }

    func startPip() { pip?.startPictureInPicture() }
}

/// AVPlayerLayer tasiyan gorunum (mini oynatici icin gerekli)
struct PlayerSurface: UIViewRepresentable {
    @ObservedObject var model: PlayerModel

    final class V: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var layerP: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> V {
        let v = V()
        v.backgroundColor = .black
        v.layerP.player = model.player
        v.layerP.videoGravity = model.gravity
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let c = AVPictureInPictureController(playerLayer: v.layerP)
            c?.canStartPictureInPictureAutomaticallyFromInline = true
            model.pip = c
        }
        return v
    }

    func updateUIView(_ v: V, context: Context) {
        v.layerP.videoGravity = model.gravity
    }
}
