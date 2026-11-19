import SwiftUI

/// Desenho do cubo "aberto" (cruz): U em cima, L F R B no meio, D embaixo.
struct CuboPlano: View {
    let facelet: String
    let cores: [String]
    var tamanho: CGFloat = 11
    var destaqueFace: Int? = nil   // face do próximo giro (URFDLB)

    private var letras: [Character] { Array(facelet) }

    var body: some View {
        let esp: CGFloat = tamanho * 0.35
        VStack(alignment: .leading, spacing: esp) {
            HStack(spacing: esp) {
                vazio
                face(0)
            }
            HStack(spacing: esp) {
                face(4)
                face(2)
                face(1)
                face(5)
            }
            HStack(spacing: esp) {
                vazio
                face(3)
            }
        }
    }

    private var vazio: some View {
        Color.clear.frame(width: tamanho * 3 + 2, height: tamanho * 3 + 2)
    }

    private func cor(_ i: Int) -> Color {
        guard letras.count == 54 else { return Color.gray.opacity(0.35) }
        let faces = Array("URFDLB")
        guard let f = faces.firstIndex(of: letras[i]), f < cores.count else { return .gray }
        return corDe(cores[f])
    }

    private func face(_ f: Int) -> some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { c in
                        RoundedRectangle(cornerRadius: tamanho * 0.18)
                            .fill(cor(f * 9 + r * 3 + c))
                            .frame(width: tamanho, height: tamanho)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: tamanho * 0.3)
                .stroke(destaqueFace == f ? ciano : Color.clear, lineWidth: 2)
                .padding(-2)
        )
    }
}
