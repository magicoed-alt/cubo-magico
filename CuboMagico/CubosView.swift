import SwiftUI

struct CubosView: View {
    @EnvironmentObject var m: Modelo
    @State private var buscandoPara: Int? = nil
    @State private var nomePadrao = ""

    var body: some View {
        NavigationStack {
            List {
                if !m.ble.ligado {
                    Section {
                        Text("Ligue o Bluetooth do iPhone e permita o acesso para o app.")
                            .foregroundColor(.orange)
                    }
                }
                ForEach(0..<2, id: \.self) { i in
                    secaoCubo(i)
                }
                Section {
                    Button("Ler bateria dos cubos") { m.ble.pedirBateria() }
                } footer: {
                    Text("Calibrar: deixe o cubo resolvido de verdade e toque em \"Está resolvido\". Faça isso se o desenho do app não bater com o seu cubo. \"Salvar como padrão\" grava o estado atual do cubo para usar numa rotina (ex.: previsão).")
                }
            }
            .navigationTitle("Cubos")
            .sheet(isPresented: Binding(get: { buscandoPara != nil }, set: { if !$0 { buscandoPara = nil; m.ble.parar() } })) {
                BuscaView(slot: buscandoPara ?? 0) { buscandoPara = nil }
                    .environmentObject(m)
            }
            .alert("Nome do padrão", isPresented: Binding(get: { m.captura != nil }, set: { if !$0 { m.captura = nil } })) {
                TextField("Ex.: Previsão", text: $nomePadrao)
                Button("Salvar") {
                    if let c = m.captura { m.salvarPadrao(nome: nomePadrao, facelet: c.facelet) }
                    nomePadrao = ""
                    m.captura = nil
                }
                Button("Cancelar", role: .cancel) { m.captura = nil }
            }
        }
    }

    @ViewBuilder
    private func secaoCubo(_ i: Int) -> some View {
        let s = m.ble.slots[i]
        let c = m.ui.cubes[safe: i]
        Section {
            HStack(alignment: .top, spacing: 14) {
                CuboPlano(facelet: c?.facelet ?? "", cores: m.config.faceColor, tamanho: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.nome.isEmpty ? "—" : s.nome).font(.headline)
                    Text(s.estado.rawValue).font(.caption)
                        .foregroundColor(s.estado == .conectado ? .green : .secondary)
                    if let b = s.bateria { Text("Bateria: \(b)%").font(.caption) }
                    if let c = c, c.hasState {
                        Text(c.solved ? "Resolvido" : "Misturado").font(.caption)
                        Text(c.lastMove).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            Button(s.id == nil ? "Procurar e conectar" : "Trocar de cubo") { buscandoPara = i; m.ble.procurar() }
            if s.id != nil {
                Button("Está resolvido (calibrar)") { m.calibrar(i) }
                    .disabled(c?.hasState != true)
                Button("Salvar estado atual como padrão") { m.capturar(i) }
                    .disabled(c?.hasState != true)
                Button("Esquecer este cubo", role: .destructive) { m.esquecerCubo(i) }
            }
        } header: {
            Text("Cubo \(i + 1)")
        }
    }
}

struct BuscaView: View {
    @EnvironmentObject var m: Modelo
    let slot: Int
    let fechar: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if m.ble.encontrados.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(m.ble.procurando ? "Procurando… gire uma face do cubo para acordá-lo." : "Nenhum cubo encontrado.")
                        }
                    }
                    ForEach(m.ble.encontrados) { e in
                        Button {
                            m.ble.escolher(e, slot: slot)
                            m.ble.parar()
                            fechar()
                        } label: {
                            HStack {
                                Image(systemName: "cube.fill").foregroundColor(ciano)
                                Text(e.nome).foregroundColor(.primary)
                                Spacer()
                                Text("\(e.rssi) dBm").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Escolha o cubo para o lugar \(slot + 1)")
                }
                Section {
                    Button("Procurar de novo") { m.ble.procurar() }
                }
            }
            .navigationTitle("Conectar cubo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { m.ble.parar(); fechar() }
                }
            }
        }
    }
}
