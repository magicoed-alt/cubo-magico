import SwiftUI

struct RotinasView: View {
    @EnvironmentObject var m: Modelo
    @State private var caminho: [UUID] = []

    var body: some View {
        NavigationStack(path: $caminho) {
            List {
                Section {
                    ForEach(m.playlists) { p in
                        HStack {
                            Button {
                                m.selecionada = p.id
                            } label: {
                                HStack {
                                    Image(systemName: p.id == m.selecionada ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(p.id == m.selecionada ? ciano : .gray)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(p.nome).foregroundColor(.primary)
                                        Text(p.passos.map { $0.titulo }.joined(separator: " → "))
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Spacer()
                            Button {
                                caminho.append(p.id)
                            } label: {
                                Image(systemName: "pencil.circle").font(.title2).foregroundColor(ciano)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { idx in m.playlists.remove(atOffsets: idx) }
                    .onMove { de, para in m.playlists.move(fromOffsets: de, toOffset: para) }
                } header: {
                    Text("Escolha a rotina do show")
                } footer: {
                    Text("Uma rotina é uma sequência de etapas. Ex.: Igualar → Resolver. Cada etapa começa quando ninguém mexe nos cubos pelo tempo de \"espera após misturar\" e você dá o primeiro giro no cubo que pegou.")
                }

                Section {
                    Button {
                        let nova = Playlist(nome: "Nova rotina", passos: [Passo(tipo: "solve")])
                        m.playlists.append(nova)
                        m.selecionada = nova.id
                    } label: {
                        Label("Nova rotina", systemImage: "plus.circle.fill")
                    }
                    Button("Restaurar rotinas de exemplo") {
                        m.playlists.append(contentsOf: playlistsPadrao())
                    }
                }
            }
            .navigationTitle("Rotinas")
            .toolbar { EditButton() }
            .navigationDestination(for: UUID.self) { id in
                EditorRotina(id: id)
            }
        }
    }
}

struct EditorRotina: View {
    @EnvironmentObject var m: Modelo
    let id: UUID

    private var indice: Int? { m.playlists.firstIndex { $0.id == id } }

    var body: some View {
        if let i = indice {
            List {
                Section("Nome") {
                    TextField("Nome da rotina", text: Binding(
                        get: { m.playlists[safe: i]?.nome ?? "" },
                        set: { v in if i < m.playlists.count { m.playlists[i].nome = v } }))
                }
                Section {
                    ForEach(Array((m.playlists[safe: i]?.passos ?? []).enumerated()), id: \.element.id) { n, passo in
                        Label("\(n + 1). \(passo.titulo)", systemImage: passo.icone)
                    }
                    .onDelete { idx in if i < m.playlists.count { m.playlists[i].passos.remove(atOffsets: idx) } }
                    .onMove { de, para in if i < m.playlists.count { m.playlists[i].passos.move(fromOffsets: de, toOffset: para) } }
                } header: {
                    Text("Etapas (na ordem)")
                } footer: {
                    Text("Arraste para mudar a ordem; deslize para apagar. \"Igualar\" precisa de 2 cubos conectados: o cubo que você girar primeiro fica igual ao outro.")
                }
                Section("Adicionar etapa") {
                    Button { adicionar(Passo(tipo: "solve")) } label: {
                        Label("Resolver", systemImage: "checkmark.circle")
                    }
                    Button { adicionar(Passo(tipo: "match")) } label: {
                        Label("Igualar ao outro cubo (2 cubos)", systemImage: "square.on.square")
                    }
                    Menu {
                        ForEach(m.todosPadroes) { p in
                            Button(p.nome) {
                                adicionar(Passo(tipo: "pattern", padraoNome: p.nome, facelet: p.facelet))
                            }
                        }
                    } label: {
                        Label("Montar um padrão…", systemImage: "square.grid.3x3.fill")
                    }
                }
            }
            .navigationTitle(m.playlists[safe: i]?.nome ?? "Rotina")
            .toolbar { EditButton() }
        } else {
            Text("Rotina apagada")
        }
    }

    private func adicionar(_ p: Passo) {
        guard let i = indice else { return }
        m.playlists[i].passos.append(p)
    }
}
