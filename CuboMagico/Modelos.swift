import SwiftUI

// MARK: - Rotinas e padrões

struct Passo: Codable, Identifiable, Hashable {
    var id = UUID()
    var tipo: String            // "solve" | "match" | "pattern"
    var padraoNome: String = ""
    var facelet: String = ""
    var announce: String = ""   // nome falado no começo da etapa (vazio = automático)

    init(tipo: String, padraoNome: String = "", facelet: String = "", announce: String = "") {
        self.tipo = tipo; self.padraoNome = padraoNome; self.facelet = facelet; self.announce = announce
    }

    // tolerante: rotinas salvas antes desta versão não têm "announce"
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        tipo = (try? c.decode(String.self, forKey: .tipo)) ?? "solve"
        padraoNome = (try? c.decode(String.self, forKey: .padraoNome)) ?? ""
        facelet = (try? c.decode(String.self, forKey: .facelet)) ?? ""
        announce = (try? c.decode(String.self, forKey: .announce)) ?? ""
    }

    var titulo: String {
        switch tipo {
        case "solve": return "Resolver"
        case "match": return "Igualar ao outro cubo (2 cubos)"
        case "pattern": return "Padrão: \(padraoNome)"
        default: return tipo
        }
    }
    var icone: String {
        switch tipo {
        case "solve": return "checkmark.circle"
        case "match": return "square.on.square"
        default: return "square.grid.3x3.fill"
        }
    }
    var paraMotor: [String: Any] {
        ["type": tipo, "patternName": padraoNome, "facelet": facelet, "announce": announce]
    }
}

struct Playlist: Codable, Identifiable, Hashable {
    var id = UUID()
    var nome: String
    var passos: [Passo]
}

struct Padrao: Codable, Identifiable, Hashable {
    var id = UUID()
    var nome: String
    var facelet: String
    var proprio: Bool = false
}

let faceletXadrez = "UDUDUDUDURLRLRLRLRFBFBFBFBFDUDUDUDUDLRLRLRLRLBFBFBFBFB"

func playlistsPadrao() -> [Playlist] {
    [
        Playlist(nome: "Resolver", passos: [Passo(tipo: "solve")]),
        Playlist(nome: "Igualar (2 cubos)", passos: [Passo(tipo: "match")]),
        Playlist(nome: "Igualar + Resolver", passos: [Passo(tipo: "match"), Passo(tipo: "solve")]),
        Playlist(nome: "Xadrez + Resolver", passos: [Passo(tipo: "pattern", padraoNome: "Xadrez", facelet: faceletXadrez),
                                                     Passo(tipo: "solve")])
    ]
}

// MARK: - Ajustes (as chaves iguais às do engine.js são enviadas ao motor)

struct Config: Codable, Equatable {
    var versao = 3
    var language = "pt"          // "pt" | "en"
    var invertLeft = false
    var invertBottom = false
    var invertBack = false
    var speechMode = "posicao"
    var orientMode = "auto"
    var faceNames = ["cima", "direita", "frente", "baixo", "esquerda", "trás"]
    var faceColor = ["branco", "vermelho", "verde", "amarelo", "laranja", "azul"]
    var topFace = 0
    var frontFace = 2
    var wordCW = "frente"
    var wordHalf = "duplo"
    var wordCCW = "reverso"
    var steps = 1
    var repeatAfter = 3
    var maxRepeats = 3
    var waitAfterMix = 7
    var readyCue = "bip"
    var readyText = "pronto"
    var doneCue = "frase"
    var doneText = "ok"
    var optimizeMs = 800
    var echoMoves = false
    var loop = false
    // só do app
    var velocidadeVoz = 1.1
    var volumeVoz = 1.0
    var modoDiscreto = false
    var mostrarCubo = true

    init() {}

    // decodifica com tolerância: chave que faltar fica com o valor padrão
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Config()
        versao = (try? c.decode(Int.self, forKey: .versao)) ?? 1
        language = (try? c.decode(String.self, forKey: .language)) ?? d.language
        invertLeft = (try? c.decode(Bool.self, forKey: .invertLeft)) ?? d.invertLeft
        invertBottom = (try? c.decode(Bool.self, forKey: .invertBottom)) ?? d.invertBottom
        invertBack = (try? c.decode(Bool.self, forKey: .invertBack)) ?? d.invertBack
        speechMode = (try? c.decode(String.self, forKey: .speechMode)) ?? d.speechMode
        orientMode = (try? c.decode(String.self, forKey: .orientMode)) ?? d.orientMode
        faceNames = (try? c.decode([String].self, forKey: .faceNames)) ?? d.faceNames
        if faceNames.count != 6 { faceNames = d.faceNames }
        faceColor = (try? c.decode([String].self, forKey: .faceColor)) ?? d.faceColor
        if faceColor.count != 6 { faceColor = d.faceColor }
        topFace = (try? c.decode(Int.self, forKey: .topFace)) ?? d.topFace
        frontFace = (try? c.decode(Int.self, forKey: .frontFace)) ?? d.frontFace
        wordCW = (try? c.decode(String.self, forKey: .wordCW)) ?? d.wordCW
        wordHalf = (try? c.decode(String.self, forKey: .wordHalf)) ?? d.wordHalf
        wordCCW = (try? c.decode(String.self, forKey: .wordCCW)) ?? d.wordCCW
        steps = (try? c.decode(Int.self, forKey: .steps)) ?? d.steps
        repeatAfter = (try? c.decode(Int.self, forKey: .repeatAfter)) ?? d.repeatAfter
        maxRepeats = (try? c.decode(Int.self, forKey: .maxRepeats)) ?? d.maxRepeats
        waitAfterMix = (try? c.decode(Int.self, forKey: .waitAfterMix)) ?? d.waitAfterMix
        readyCue = (try? c.decode(String.self, forKey: .readyCue)) ?? d.readyCue
        readyText = (try? c.decode(String.self, forKey: .readyText)) ?? d.readyText
        doneCue = (try? c.decode(String.self, forKey: .doneCue)) ?? d.doneCue
        doneText = (try? c.decode(String.self, forKey: .doneText)) ?? d.doneText
        optimizeMs = (try? c.decode(Int.self, forKey: .optimizeMs)) ?? d.optimizeMs
        echoMoves = (try? c.decode(Bool.self, forKey: .echoMoves)) ?? d.echoMoves
        loop = (try? c.decode(Bool.self, forKey: .loop)) ?? d.loop
        velocidadeVoz = (try? c.decode(Double.self, forKey: .velocidadeVoz)) ?? d.velocidadeVoz
        volumeVoz = (try? c.decode(Double.self, forKey: .volumeVoz)) ?? d.volumeVoz
        modoDiscreto = (try? c.decode(Bool.self, forKey: .modoDiscreto)) ?? d.modoDiscreto
        mostrarCubo = (try? c.decode(Bool.self, forKey: .mostrarCubo)) ?? d.mostrarCubo
        if versao < 2 {
            // versão 2: mágica de olhos fechados (posição + orientação automática, espera de 7 s)
            speechMode = d.speechMode
            orientMode = d.orientMode
            wordCW = d.wordCW
            wordHalf = d.wordHalf
            wordCCW = d.wordCCW
            waitAfterMix = d.waitAfterMix
            versao = 2
        }
        if versao < 3 {
            // versão 3: ao terminar a etapa fala "o cubo está resolvido" / "the cube is solved"
            if doneCue == "bip" { doneCue = d.doneCue }
            versao = 3
        }
    }

    /// Palavras faladas de cada idioma (o inglês segue o padrão do CubeSmith)
    mutating func aplicarIdioma(_ l: String) {
        language = l
        if l == "en" {
            faceNames = ["top", "right", "front", "bottom", "left", "back"]
            wordCW = "forward"; wordHalf = "double"; wordCCW = "reverse"
            readyText = "ready"; doneText = "done"
            invertLeft = true; invertBottom = true; invertBack = true
        } else {
            let d = Config()
            faceNames = d.faceNames
            wordCW = d.wordCW; wordHalf = d.wordHalf; wordCCW = d.wordCCW
            readyText = d.readyText; doneText = d.doneText
            invertLeft = false; invertBottom = false; invertBack = false
        }
    }
}

let nomesDasCores = ["branco", "vermelho", "verde", "amarelo", "laranja", "azul"]
let nomesDasFaces = ["U (cima)", "R (direita)", "F (frente)", "D (baixo)", "L (esquerda)", "B (trás)"]

func corDe(_ nome: String) -> Color {
    switch nome.lowercased() {
    case "branco": return Color(white: 0.96)
    case "vermelho": return Color(red: 0.86, green: 0.10, blue: 0.12)
    case "verde": return Color(red: 0.05, green: 0.70, blue: 0.25)
    case "amarelo": return Color(red: 1.0, green: 0.86, blue: 0.0)
    case "laranja": return Color(red: 1.0, green: 0.50, blue: 0.0)
    case "azul": return Color(red: 0.10, green: 0.35, blue: 0.95)
    default: return Color.gray
    }
}

let ciano = Color(red: 0.0, green: 0.85, blue: 0.95)

// MARK: - Estado vindo do motor (engine.js → E_ui)

struct UICubo: Codable {
    var connected: Bool
    var hasState: Bool
    var facelet: String
    var solved: Bool
    var lastMove: String
    var moves: Int
}

struct UIMov: Codable, Hashable {
    var label: String
    var notation: String
    var face: Int
    var power: Int
    var speech: String
}

struct UIRun: Codable {
    var name: String
    var phase: String
    var phaseLabel: String
    var stepIndex: Int
    var stepCount: Int
    var stepName: String
    var active: Int
    var next: [UIMov]
    var total: Int
    var done: Int
    var half: Bool
    var message: String
    var target: String
    var display: String?   // instrução atual (o que aparece grande no topo)
    var last: Bool?        // é o último giro da etapa
}

struct EstadoUI: Codable {
    var cubes: [UICubo]
    var run: UIRun?
    var view: [Int]?       // [face de cima, face da direita] como o cubo está na mão

    static let vazio = EstadoUI(cubes: [], run: nil, view: nil)

    var topo: Int { view?.first ?? 0 }
    var direita: Int { (view?.count ?? 0) > 1 ? view![1] : 1 }
}

struct Captura: Identifiable {
    let id = UUID()
    let slot: Int
    let facelet: String
}
