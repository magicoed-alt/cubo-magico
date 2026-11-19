import SwiftUI

struct ShowView: View {
    @EnvironmentObject var m: Modelo

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.05, blue: 0.09).ignoresSafeArea()
                if m.config.modoDiscreto && m.rodando {
                    discreto
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            escolhaRotina
                            botaoPrincipal
                            if let r = m.ui.run { estado(r) }
                            if m.config.mostrarCubo { cubos }
                            if !m.ultimaFala.isEmpty {
                                Text("🔊 \(m.ultimaFala)")
                                    .font(.footnote).foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cubo Mágico")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - partes

    private var escolhaRotina: some View {
        Menu {
            ForEach(m.playlists) { p in
                Button {
                    m.selecionada = p.id
                } label: {
                    if p.id == m.selecionada { Label(p.nome, systemImage: "checkmark") } else { Text(p.nome) }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ROTINA").font(.caption2).foregroundColor(ciano)
                    Text(m.playlistAtual?.nome ?? "Escolha uma rotina")
                        .font(.title3.bold()).foregroundColor(.white)
                    Text(m.playlistAtual?.passos.map { $0.titulo }.joined(separator: "  →  ") ?? "")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").foregroundColor(ciano)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
        }
        .disabled(m.rodando)
    }

    private var botaoPrincipal: some View {
        Button {
            if m.rodando { m.parar() } else { m.iniciar() }
        } label: {
            Text(m.rodando ? "PARAR" : "COMEÇAR")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 14).fill(m.rodando ? Color.red.opacity(0.8) : ciano))
                .foregroundColor(m.rodando ? .white : .black)
        }
        .disabled(m.playlistAtual == nil)
    }

    @ViewBuilder
    private func estado(_ r: UIRun) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(r.phaseLabel).font(.headline).foregroundColor(corDaFase(r.phase))
                Spacer()
                if r.phase != "fim" {
                    Text("Etapa \(min(r.stepIndex + 1, r.stepCount)) de \(r.stepCount)")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                }
            }
            if !r.stepName.isEmpty {
                Text(r.stepName).font(.subheadline).foregroundColor(.white)
            }
            if !r.message.isEmpty {
                Text(r.message).font(.subheadline.bold()).foregroundColor(.orange)
            }
            if r.phase == "guide", let prox = r.next.first {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(corDe(m.config.faceColor[safe: prox.face] ?? ""))
                        .frame(width: 64, height: 64)
                        .overlay(Text(["↻", "2×", "↺"][prox.power % 3]).font(.system(size: 30, weight: .black))
                            .foregroundColor(.black.opacity(0.75)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prox.label).font(.title.bold()).foregroundColor(.white)
                        Text("\(prox.notation)  ·  faltam \(r.next.count)\(r.half ? "  ·  meio giro feito" : "")")
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                }
                Text(r.next.dropFirst().prefix(12).map { $0.notation }.joined(separator: " "))
                    .font(.system(.body, design: .monospaced)).foregroundColor(.white.opacity(0.5))
            }
            HStack(spacing: 10) {
                botaoPequeno(r.phase == "wait" ? "Pular espera" : "Repetir", "speaker.wave.2") { m.tocar() }
                botaoPequeno("Reorientar", "arrow.up.and.down.and.arrow.left.and.right") { m.reorientar() }
                botaoPequeno("Reiniciar etapa", "arrow.counterclockwise") { m.reiniciarEtapa() }
                botaoPequeno("Próxima", "forward.end") { m.proximaEtapa() }
            }
            .disabled(r.phase == "fim")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
    }

    private var cubos: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(0..<2, id: \.self) { i in
                let c = m.ui.cubes[safe: i]
                let ativo = m.ui.run?.active == i
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle().fill((c?.connected ?? false) ? Color.green : Color.gray).frame(width: 8, height: 8)
                        Text(m.ble.slots[i].nome.isEmpty ? "Cubo \(i + 1)" : m.ble.slots[i].nome)
                            .font(.caption.bold()).foregroundColor(ativo ? ciano : .white)
                            .lineLimit(1)
                    }
                    CuboPlano(facelet: c?.facelet ?? "", cores: m.config.faceColor, tamanho: 8,
                              destaqueFace: ativo ? m.ui.run?.next.first?.face : nil)
                    Text(c?.lastMove ?? "").font(.caption2).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12)
                    .stroke(ativo ? ciano : Color.white.opacity(0.15), lineWidth: ativo ? 2 : 1))
            }
        }
    }

    /// Tela quase preta para usar no palco
    private var discreto: some View {
        VStack(spacing: 12) {
            Spacer()
            if let r = m.ui.run {
                Text(r.phase == "guide" ? (r.next.first?.label ?? "") : r.phaseLabel)
                    .font(.title2.bold()).foregroundColor(.white.opacity(0.25))
                Text("\(r.next.count)").font(.caption).foregroundColor(.white.opacity(0.15))
            }
            Spacer()
            Text("toque 2× para sair do modo discreto")
                .font(.caption2).foregroundColor(.white.opacity(0.12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { m.config.modoDiscreto = false }
        .ignoresSafeArea()
    }

    private func botaoPequeno(_ t: String, _ icone: String, _ acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            VStack(spacing: 4) {
                Image(systemName: icone)
                Text(t).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
            .foregroundColor(ciano)
        }
    }

    private func corDaFase(_ f: String) -> Color {
        switch f {
        case "wait": return .orange
        case "armed": return .green
        case "guide": return ciano
        case "orient1", "orient2": return .yellow
        default: return .white
        }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { (i >= 0 && i < count) ? self[i] : nil }
}
