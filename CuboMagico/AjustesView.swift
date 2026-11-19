import SwiftUI

struct AjustesView: View {
    @EnvironmentObject var m: Modelo

    var body: some View {
        NavigationStack {
            Form {
                secaoVoz
                secaoInicio
                secaoSolucao
                secaoCores
                secaoSegurar
                secaoTela
                secaoPadroes
            }
            .navigationTitle("Ajustes")
        }
    }

    @ViewBuilder
    private var secaoVoz: some View {
        Section {
            Picker("Como falar", selection: $m.config.speechMode) {
                Text("Cor da face — \"vermelho horário\"").tag("cores")
                Text("Posição — \"direita horário\"").tag("posicao")
                Text("Notação — \"érre linha\"").tag("notacao")
            }
            .pickerStyle(.inline)
            VStack(alignment: .leading) {
                Text("Velocidade da voz: \(Int(m.config.velocidadeVoz * 100))%")
                Slider(value: $m.config.velocidadeVoz, in: 0.6...1.8, step: 0.05)
            }
            VStack(alignment: .leading) {
                Text("Volume: \(Int(m.config.volumeVoz * 100))%")
                Slider(value: $m.config.volumeVoz, in: 0.2...1.0, step: 0.05)
            }
            if m.config.speechMode != "notacao" {
                campo("Sentido horário", $m.config.wordCW)
                campo("Duas vezes (180°)", $m.config.wordHalf)
                campo("Anti-horário", $m.config.wordCCW)
            }
            Stepper("Giros por fala: \(m.config.steps)", value: $m.config.steps, in: 1...4)
            Stepper(m.config.repeatAfter == 0 ? "Repetir a fala: nunca" : "Repetir a fala após \(m.config.repeatAfter) s parado",
                    value: $m.config.repeatAfter, in: 0...15)
            Stepper("Máximo de repetições: \(m.config.maxRepeats)×", value: $m.config.maxRepeats, in: 0...10)
            Button("Testar a voz") { m.testarGiro(Int.random(in: 0..<18)) }
        } header: {
            Text("Guia por áudio")
        } footer: {
            Text("A voz sai onde o iPhone estiver tocando áudio: no Ray-Ban Meta, conecte o óculos ao iPhone antes. Um toque na haste do óculos repete a instrução (ou pula a espera).")
        }
    }

    @ViewBuilder
    private var secaoInicio: some View {
        Section {
            Stepper("Espera após misturar: \(m.config.waitAfterMix) s", value: $m.config.waitAfterMix, in: 1...30)
            Picker("Aviso de pronto", selection: $m.config.readyCue) {
                Text("Nenhum").tag("nada")
                Text("Bip").tag("bip")
                Text("Voz").tag("voz")
            }
            if m.config.readyCue == "voz" { campo("Texto do pronto", $m.config.readyText) }
            Picker("Aviso de etapa concluída", selection: $m.config.doneCue) {
                Text("Nenhum").tag("nada")
                Text("Bip").tag("bip")
                Text("Voz").tag("voz")
            }
            if m.config.doneCue == "voz" { campo("Texto do concluído", $m.config.doneText) }
            Toggle("Ao terminar, recomeçar a rotina", isOn: $m.config.loop)
        } header: {
            Text("Início das etapas")
        } footer: {
            Text("Cada etapa espera ninguém mexer nos cubos por esse tempo (fim da mistura). Depois disso, o primeiro giro que você der escolhe o cubo e o app começa a falar.")
        }
    }

    @ViewBuilder
    private var secaoSolucao: some View {
        Section {
            VStack(alignment: .leading) {
                Text(m.config.optimizeMs == 0 ? "Procurar solução mais curta: não"
                     : String(format: "Procurar solução mais curta por %.1f s", Double(m.config.optimizeMs) / 1000))
                Slider(value: Binding(get: { Double(m.config.optimizeMs) },
                                      set: { m.config.optimizeMs = Int($0) }),
                       in: 0...3000, step: 100)
            }
        } header: {
            Text("Solução")
        } footer: {
            Text("Com 0 s a solução sai na hora (~20 a 21 giros). Com mais tempo o app tenta achar 18–19 giros antes de começar a falar.")
        }
    }

    @ViewBuilder
    private var secaoCores: some View {
        Section {
            ForEach(0..<6, id: \.self) { f in
                Picker(selection: $m.config.faceColor[f]) {
                    ForEach(nomesDasCores, id: \.self) { c in
                        HStack {
                            Circle().fill(corDe(c)).frame(width: 12, height: 12)
                            Text(c)
                        }
                        .tag(c)
                    }
                } label: {
                    Text("Face \(nomesDasFaces[f])")
                }
            }
            Toggle("Falar cada giro (teste, fora da rotina)", isOn: $m.config.echoMoves)
        } header: {
            Text("Cores do cubo")
        } footer: {
            Text("Ligue \"Falar cada giro\", gire a face branca no sentido horário e confira se o app fala \"branco horário\". Se falar outra cor, ajuste aqui.")
        }
    }

    @ViewBuilder
    private var secaoSegurar: some View {
        if m.config.speechMode != "cores" {
            Section {
                Picker("Em cima", selection: $m.config.topFace) {
                    ForEach(0..<6, id: \.self) { f in Text(m.config.faceColor[f]).tag(f) }
                }
                Picker("Na frente", selection: $m.config.frontFace) {
                    ForEach(0..<6, id: \.self) { f in Text(m.config.faceColor[f]).tag(f) }
                }
            } header: {
                Text("Como você segura o cubo")
            } footer: {
                Text("Nos modos posição e notação, segure sempre com essas cores em cima e na frente.")
            }
        }
    }

    @ViewBuilder
    private var secaoTela: some View {
        Section("Tela") {
            Toggle("Modo discreto (tela preta durante a rotina)", isOn: $m.config.modoDiscreto)
            Toggle("Mostrar os cubos na tela", isOn: $m.config.mostrarCubo)
        }
    }

    @ViewBuilder
    private var secaoPadroes: some View {
        Section("Meus padrões") {
            if m.padroesProprios.isEmpty {
                Text("Nenhum. Monte um padrão no cubo e use \"Salvar estado atual como padrão\" na aba Cubos.")
                    .font(.caption).foregroundColor(.secondary)
            }
            ForEach(m.padroesProprios) { p in
                HStack {
                    CuboPlano(facelet: p.facelet, cores: m.config.faceColor, tamanho: 6)
                    Text(p.nome)
                }
            }
            .onDelete { idx in m.padroesProprios.remove(atOffsets: idx) }
        }
    }

    private func campo(_ titulo: String, _ b: Binding<String>) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField(titulo, text: b)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ciano)
        }
    }
}
