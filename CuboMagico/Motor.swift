import Foundation
import JavaScriptCore

/// Roda o engine.js (solver + rotinas) no JavaScriptCore, numa fila própria.
final class Motor {
    private let fila = DispatchQueue(label: "cubo.motor", qos: .userInitiated)
    private var ctx: JSContext?

    /// ações pedidas pelo motor (falar, bip, calibrado...) — chamado na main
    var aoAgir: (([[String: Any]]) -> Void)?
    /// novo estado para as telas — chamado na main
    var aoAtualizar: ((EstadoUI) -> Void)?
    /// padrões prontos carregados — chamado na main
    var aoCarregarPadroes: (([Padrao]) -> Void)?

    init() {
        fila.async { self.carregar() }
    }

    private func carregar() {
        let novo: JSContext? = JSContext()
        guard let c = novo else { return }
        c.exceptionHandler = { _, erro in
            print("Erro no JS:", erro?.toString() ?? "?")
        }
        for nome in ["min2phase", "cube", "engine"] {
            if let url = Bundle.main.url(forResource: nome, withExtension: "txt"),
               let codigo = try? String(contentsOf: url, encoding: .utf8) {
                c.evaluateScript(codigo, withSourceURL: url)
            } else {
                print("Arquivo não encontrado:", nome)
            }
        }
        ctx = c
        let lista = chamar("E_patterns", [])
        if let d = lista.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]] {
            let padroes: [Padrao] = arr.compactMap { item in
                guard let n = item["name"] as? String, let f = item["facelet"] as? String else { return nil }
                return Padrao(nome: n, facelet: f, proprio: false)
            }
            DispatchQueue.main.async { self.aoCarregarPadroes?(padroes) }
        }
        _ = chamar("E_init", [])   // monta as tabelas do solver (~1 s)
        publicarUI()
    }

    @discardableResult
    private func chamar(_ funcao: String, _ args: [Any]) -> String {
        guard let c = ctx else { return "[]" }
        let fv: JSValue? = c.objectForKeyedSubscript(funcao)
        guard let f = fv, !f.isUndefined else { return "[]" }
        let rv: JSValue? = f.call(withArguments: args)
        guard let r = rv else { return "[]" }
        let s: String? = r.toString()
        return s ?? "[]"
    }

    private func processar(_ json: String) {
        guard json != "[]", let d = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]], !arr.isEmpty else { return }
        DispatchQueue.main.async { self.aoAgir?(arr) }
    }

    private func publicarUI() {
        let txt = chamar("E_ui", [])
        guard let d = txt.data(using: .utf8), let estado = try? JSONDecoder().decode(EstadoUI.self, from: d) else { return }
        DispatchQueue.main.async { self.aoAtualizar?(estado) }
    }

    private func agora() -> Double { Date().timeIntervalSince1970 * 1000 }

    // MARK: - chamadas do app

    func dados(slot: Int, _ dados: Data) {
        let hex = dados.map { String(format: "%02x", $0) }.joined()
        let t = agora()
        fila.async {
            self.processar(self.chamar("E_feed", [slot, hex, t]))
            self.publicarUI()
        }
    }

    func tick() {
        let t = agora()
        fila.async {
            self.processar(self.chamar("E_tick", [t]))
            self.publicarUI()
        }
    }

    func comando(_ nome: String, _ arg: [String: Any] = [:]) {
        let t = agora()
        var json = "{}"
        if let d = try? JSONSerialization.data(withJSONObject: arg), let s = String(data: d, encoding: .utf8) { json = s }
        fila.async {
            self.processar(self.chamar("E_cmd", [nome, json, t]))
            self.publicarUI()
        }
    }

    func configurar(_ config: Config) {
        guard let d = try? JSONEncoder().encode(config), let s = String(data: d, encoding: .utf8) else { return }
        fila.async {
            self.chamar("E_config", [s])
            self.publicarUI()
        }
    }
}
