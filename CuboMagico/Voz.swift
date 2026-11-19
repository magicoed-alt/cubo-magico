import AVFoundation
import MediaPlayer

/// Fala as instruções (sai no Ray-Ban Meta / fone Bluetooth conectado) e recebe
/// o toque do óculos (play/pause) como comando.
final class Voz: NSObject {
    static let shared = Voz()

    private let sintetizador = AVSpeechSynthesizer()
    private var silencio: AVAudioPlayer?
    private var bipPlayer: AVAudioPlayer?
    private var ultimoToque = Date.distantPast

    var velocidade: Double = 1.1
    var volume: Double = 1.0

    /// toque no óculos / fone (play, pause)
    var aoTocar: (() -> Void)?
    /// próxima faixa (toque duplo em muitos fones)
    var aoProxima: (() -> Void)?
    /// faixa anterior
    var aoAnterior: (() -> Void)?

    override init() {
        super.init()
        configurarSessao()
        prepararSons()
        configurarControles()
        NotificationCenter.default.addObserver(self, selector: #selector(interrupcao(_:)),
                                               name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mudouRota(_:)),
                                               name: AVAudioSession.routeChangeNotification, object: nil)
    }

    private func configurarSessao() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(.playback, mode: .spokenAudio, options: [])
            try s.setActive(true)
        } catch {
            print("Sessão de áudio:", error)
        }
    }

    // Um áudio silencioso em loop mantém o app vivo com a tela bloqueada,
    // mantém o óculos "acordado" (sem cortar o começo das falas) e faz o app
    // receber os toques de play/pause.
    private func prepararSons() {
        if let p = try? AVAudioPlayer(data: Voz.wav(segundos: 2.0, frequencia: 0, volume: 0)) {
            p.numberOfLoops = -1
            p.volume = 1
            p.prepareToPlay()
            silencio = p
        }
        if let b = try? AVAudioPlayer(data: Voz.wav(segundos: 0.13, frequencia: 1046, volume: 0.6)) {
            b.prepareToPlay()
            bipPlayer = b
        }
    }

    func ligar() {
        configurarSessao()
        if silencio?.isPlaying != true { silencio?.play() }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Cubo Mágico",
            MPMediaItemPropertyArtist: "Digital Magic",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
    }

    private func configurarControles() {
        let cc = MPRemoteCommandCenter.shared()
        let toque: (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus = { [weak self] _ in
            self?.toqueRecebido()
            return .success
        }
        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.addTarget(handler: toque)
        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget(handler: toque)
        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget(handler: toque)
        cc.nextTrackCommand.isEnabled = true
        cc.nextTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.aoProxima?() }
            return .success
        }
        cc.previousTrackCommand.isEnabled = true
        cc.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.aoAnterior?() }
            return .success
        }
    }

    private func toqueRecebido() {
        let agora = Date()
        if agora.timeIntervalSince(ultimoToque) < 0.4 { return }
        ultimoToque = agora
        // o silêncio precisa continuar tocando para o próximo toque chegar
        DispatchQueue.main.async {
            if self.silencio?.isPlaying != true { self.silencio?.play() }
            self.aoTocar?()
        }
    }

    func falar(_ texto: String) {
        guard !texto.isEmpty else { return }
        if silencio?.isPlaying != true { silencio?.play() }
        if sintetizador.isSpeaking { sintetizador.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: texto)
        u.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        let taxa = AVSpeechUtteranceDefaultSpeechRate * Float(velocidade)
        u.rate = min(AVSpeechUtteranceMaximumSpeechRate, max(AVSpeechUtteranceMinimumSpeechRate, taxa))
        u.volume = Float(volume)
        u.preUtteranceDelay = 0
        u.postUtteranceDelay = 0
        sintetizador.speak(u)
    }

    func bip() {
        guard let b = bipPlayer else { return }
        b.volume = Float(volume)
        b.currentTime = 0
        b.play()
    }

    @objc private func interrupcao(_ n: Notification) {
        guard let info = n.userInfo, let v = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let tipo = AVAudioSession.InterruptionType(rawValue: v) else { return }
        if tipo == .ended {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.ligar() }
        }
    }

    @objc private func mudouRota(_ n: Notification) {
        // óculos conectou/desconectou: garante que o silêncio continua
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.silencio?.isPlaying != true { self.silencio?.play() }
        }
    }

    /// WAV PCM 16-bit mono gerado na memória (silêncio ou um tom)
    static func wav(segundos: Double, frequencia: Double, volume: Double) -> Data {
        let taxa = 22050
        let n = Int(Double(taxa) * segundos)
        var amostras = [Int16](repeating: 0, count: n)
        if frequencia > 0 {
            for i in 0..<n {
                let t = Double(i) / Double(taxa)
                var env = 1.0
                let borda = 0.015
                if t < borda { env = t / borda }
                if t > segundos - borda { env = max(0, (segundos - t) / borda) }
                amostras[i] = Int16(sin(2 * Double.pi * frequencia * t) * 32767 * volume * env)
            }
        }
        var d = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { d.append(contentsOf: $0) } }
        let bytesDados = UInt32(n * 2)
        d.append(contentsOf: Array("RIFF".utf8)); u32(36 + bytesDados)
        d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1)
        u32(UInt32(taxa)); u32(UInt32(taxa * 2)); u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(bytesDados)
        amostras.withUnsafeBufferPointer { buf in
            for a in buf { var x = a.littleEndian; withUnsafeBytes(of: &x) { d.append(contentsOf: $0) } }
        }
        return d
    }
}
