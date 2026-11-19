import SwiftUI
import Combine

/// Junta tudo: ajustes, rotinas, Bluetooth, motor e voz.
final class Modelo: ObservableObject {
    @Published var config: Config {
        didSet {
            guard config != oldValue else { return }
            guardar(config, "config")
            aplicarConfig()
        }
    }
    @Published var playlists: [Playlist] { didSet { guardar(playlists, "playlists") } }
    @Published var padroesProprios: [Padrao] { didSet { guardar(padroesProprios, "padroes") } }
    @Published var selecionada: UUID? {
        didSet { UserDefaults.standard.set(selecionada?.uuidString, forKey: "selecionada") }
    }
    @Published var ui = EstadoUI.vazio
    @Published var padroesProntos: [Padrao] = []
    @Published var ultimaFala = ""
    @Published var captura: Captura?

    let ble = BLE()
    let motor = Motor()
    private var timer: Timer?
    private var assinaturas = Set<AnyCancellable>()

    init() {
        config = Modelo.ler(Config.self, "config") ?? Config()
        let pl = Modelo.ler([Playlist].self, "playlists") ?? []
        playlists = pl.isEmpty ? playlistsPadrao() : pl
        padroesProprios = Modelo.ler([Padrao].self, "padroes") ?? []
        if let s = UserDefaults.standard.string(forKey: "selecionada"), let id = UUID(uuidString: s) {
            selecionada = id
        } else {
            selecionada = nil
        }
        if selecionada == nil || !playlists.contains(where: { $0.id == selecionada }) {
            selecionada = playlists.first?.id
        }

        motor.aoAtualizar = { [weak self] estado in self?.ui = estado }
        motor.aoAgir = { [weak self] acoes in self?.executar(acoes) }
        motor.aoCarregarPadroes = { [weak self] lista in self?.padroesProntos = lista }

        ble.aoReceber = { [weak self] slot, dados in self?.motor.dados(slot: slot, dados) }
        ble.aoMudarConexao = { [weak self] slot, conectado, id in
            guard let self = self else { return }
            self.motor.comando("connected", ["slot": slot, "on": conectado])
            if conectado, let id = id {
                let raw = self.calibracoes()[id.uuidString] ?? ""
                self.motor.comando("setCalib", ["slot": slot, "raw": raw])
            }
        }
        // repassa mudanças do BLE para as telas que observam o Modelo
        ble.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &assinaturas)

        let voz = Voz.shared
        voz.aoTocar = { [weak self] in self?.motor.comando("tap") }
        voz.aoProxima = { [weak self] in self?.motor.comando("reorient") }
        voz.aoAnterior = { [weak self] in self?.motor.comando("reorient") }
        voz.ligar()

        aplicarConfig()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.motor.tick()
        }
    }

    // MARK: - persistência

    private func guardar<T: Encodable>(_ valor: T, _ chave: String) {
        if let d = try? JSONEncoder().encode(valor) { UserDefaults.standard.set(d, forKey: chave) }
    }

    private static func ler<T: Decodable>(_ tipo: T.Type, _ chave: String) -> T? {
        guard let d = UserDefaults.standard.data(forKey: chave) else { return nil }
        return try? JSONDecoder().decode(tipo, from: d)
    }

    private func calibracoes() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: "calibracoes") as? [String: String]) ?? [:]
    }

    private func aplicarConfig() {
        Voz.shared.velocidade = config.velocidadeVoz
        Voz.shared.volume = config.volumeVoz
        motor.configurar(config)
    }

    // MARK: - ações do motor

    private func executar(_ acoes: [[String: Any]]) {
        for a in acoes {
            switch a["type"] as? String ?? "" {
            case "speak":
                let t = a["text"] as? String ?? ""
                ultimaFala = t
                Voz.shared.falar(t)
            case "cue":
                Voz.shared.bip()
            case "calibrated":
                if let slot = a["slot"] as? Int, let raw = a["raw"] as? String, let id = ble.slots[slot].id {
                    var c = calibracoes()
                    c[id.uuidString] = raw
                    UserDefaults.standard.set(c, forKey: "calibracoes")
                }
            case "captured":
                if let slot = a["slot"] as? Int, let f = a["facelet"] as? String {
                    captura = Captura(slot: slot, facelet: f)
                }
            default:
                break
            }
        }
    }

    // MARK: - comandos das telas

    var playlistAtual: Playlist? { playlists.first { $0.id == selecionada } }
    var todosPadroes: [Padrao] { padroesProntos + padroesProprios }
    var rodando: Bool { ui.run != nil && ui.run?.phase != "fim" }

    func iniciar() {
        guard let p = playlistAtual else { return }
        Voz.shared.ligar()
        motor.comando("start", ["name": p.nome, "steps": p.passos.map { $0.paraMotor }])
    }

    func parar() { motor.comando("stop") }
    func tocar() { motor.comando("tap") }
    func reiniciarEtapa() { motor.comando("restartStep") }
    func reorientar() { motor.comando("reorient") }
    func proximaEtapa() { motor.comando("nextStep") }
    func calibrar(_ slot: Int) { motor.comando("calibrate", ["slot": slot]) }
    func capturar(_ slot: Int) { motor.comando("capture", ["slot": slot]) }
    func testarGiro(_ m: Int) { motor.comando("testMove", ["m": m]) }
    func dizer(_ texto: String) { motor.comando("say", ["text": texto]) }

    func salvarPadrao(nome: String, facelet: String) {
        let n = nome.trimmingCharacters(in: .whitespaces)
        padroesProprios.append(Padrao(nome: n.isEmpty ? "Meu padrão" : n, facelet: facelet, proprio: true))
    }

    func esquecerCubo(_ slot: Int) {
        if let id = ble.slots[slot].id {
            var c = calibracoes()
            c[id.uuidString] = nil
            UserDefaults.standard.set(c, forKey: "calibracoes")
        }
        ble.esquecer(slot)
    }
}
