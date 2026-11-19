import SwiftUI

/// Cubo em 3D (como no CubeSmith): mostra as faces de cima, da frente e da direita,
/// do jeito que o cubo está na mão (topo = face de cima, direita = face da direita).
struct CuboIso: View {
    let facelet: String
    let cores: [String]
    var largura: CGFloat = 130
    var topo: Int = 0          // face interna (URFDLB) que está em cima
    var direita: Int = 1       // face interna que está à direita
    var destaqueFace: Int? = nil

    private typealias V3 = (Double, Double, Double)

    private static let vetores: [V3] = [(0, 1, 0), (1, 0, 0), (0, 0, 1), (0, -1, 0), (-1, 0, 0), (0, 0, -1)]

    /// posição (cubinho, de -1 a 1) do adesivo r,c da face f, na ordem do facelet de Kociemba
    private static func posicao(_ f: Int, _ r: Int, _ c: Int) -> V3 {
        let r = Double(r), c = Double(c)
        switch f {
        case 0: return (c - 1, 1, r - 1)
        case 1: return (1, 1 - r, 1 - c)
        case 2: return (c - 1, 1 - r, 1)
        case 3: return (c - 1, -1, 1 - r)
        case 4: return (-1, 1 - r, c - 1)
        default: return (1 - c, 1 - r, -1)
        }
    }

    var body: some View {
        Canvas { ctx, size in
            desenhar(ctx, size)
        }
        .frame(width: largura, height: largura * 6 / 5.2)
    }

    private func dot(_ a: V3, _ b: V3) -> Double { a.0 * b.0 + a.1 * b.1 + a.2 * b.2 }
    private func cross(_ a: V3, _ b: V3) -> V3 {
        (a.1 * b.2 - a.2 * b.1, a.2 * b.0 - a.0 * b.2, a.0 * b.1 - a.1 * b.0)
    }

    private func desenhar(_ ctx: GraphicsContext, _ size: CGSize) {
        var up = CuboIso.vetores[0], rt = CuboIso.vetores[1]
        if topo >= 0, topo < 6, direita >= 0, direita < 6, dot(CuboIso.vetores[topo], CuboIso.vetores[direita]) == 0 {
            up = CuboIso.vetores[topo]; rt = CuboIso.vetores[direita]
        }
        let fr = cross(rt, up)
        func fisico(_ v: V3) -> V3 { (dot(v, rt), dot(v, up), dot(v, fr)) }

        let s = Double(size.width) / 5.25
        let cx = Double(size.width) / 2, cy = Double(size.height) / 2
        func tela(_ p: V3) -> CGPoint {
            CGPoint(x: cx + (p.0 - p.2) * 0.866 * s, y: cy + (-p.1 + (p.0 + p.2) * 0.5) * s)
        }
        // eixos de cada face visível: normal, a, b
        let faces: [(V3, V3, V3, Double)] = [
            ((0, 1, 0), (1, 0, 0), (0, 0, 1), 0.0),     // cima
            ((0, 0, 1), (1, 0, 0), (0, 1, 0), 0.0),     // frente
            ((1, 0, 0), (0, 0, 1), (0, 1, 0), 0.14)     // direita (um pouco mais escura)
        ]
        func quad(_ c: V3, _ a: V3, _ b: V3, _ h: Double) -> [CGPoint] {
            [tela((c.0 + h * (a.0 + b.0), c.1 + h * (a.1 + b.1), c.2 + h * (a.2 + b.2))),
             tela((c.0 + h * (a.0 - b.0), c.1 + h * (a.1 - b.1), c.2 + h * (a.2 - b.2))),
             tela((c.0 + h * (-a.0 - b.0), c.1 + h * (-a.1 - b.1), c.2 + h * (-a.2 - b.2))),
             tela((c.0 + h * (-a.0 + b.0), c.1 + h * (-a.1 + b.1), c.2 + h * (-a.2 + b.2)))]
        }
        // corpo preto
        for (n, a, b, _) in faces {
            let c: V3 = (n.0 * 1.5, n.1 * 1.5, n.2 * 1.5)
            ctx.fill(arredondado(quad(c, a, b, 1.5), 0), with: .color(.black))
        }
        // adesivos
        let letras = Array(facelet)
        let ordem = Array("URFDLB")
        for f in 0..<6 {
            let n = fisico(CuboIso.vetores[f])
            guard let fi = faces.firstIndex(where: { $0.0 == n }) else { continue }
            let (_, a, b, sombra) = faces[fi]
            for r in 0..<3 {
                for c in 0..<3 {
                    let p = fisico(CuboIso.posicao(f, r, c))
                    let centro: V3 = (p.0 + n.0 * 0.5, p.1 + n.1 * 0.5, p.2 + n.2 * 0.5)
                    var cor = Color.gray.opacity(0.4)
                    let i = f * 9 + r * 3 + c
                    if letras.count == 54, let k = ordem.firstIndex(of: letras[i]), k < cores.count {
                        cor = corDe(cores[k])
                    }
                    let forma = arredondado(quad(centro, a, b, 0.42), 0.28)
                    ctx.fill(forma, with: .color(cor))
                    if sombra > 0 { ctx.fill(forma, with: .color(.black.opacity(sombra))) }
                }
            }
            if destaqueFace == f {
                let c: V3 = (n.0 * 1.5, n.1 * 1.5, n.2 * 1.5)
                ctx.stroke(arredondado(quad(c, a, b, 1.5), 0.06), with: .color(ciano), lineWidth: 3)
            }
        }
    }

    /// polígono com cantos arredondados (t = fração do lado usada na curva)
    private func arredondado(_ p: [CGPoint], _ t: CGFloat) -> Path {
        var path = Path()
        let n = p.count
        func lerp(_ a: CGPoint, _ b: CGPoint, _ k: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k)
        }
        for i in 0..<n {
            let ant = p[(i + n - 1) % n], atual = p[i], prox = p[(i + 1) % n]
            let entrada = lerp(atual, ant, t), saida = lerp(atual, prox, t)
            if i == 0 { path.move(to: entrada) } else { path.addLine(to: entrada) }
            path.addQuadCurve(to: saida, control: atual)
        }
        path.closeSubpath()
        return path
    }
}
