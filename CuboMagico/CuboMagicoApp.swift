import SwiftUI

@main
struct CuboMagicoApp: App {
    @StateObject private var modelo = Modelo()

    var body: some Scene {
        WindowGroup {
            TabView {
                ShowView()
                    .tabItem { Label("Show", systemImage: "play.circle.fill") }
                RotinasView()
                    .tabItem { Label("Rotinas", systemImage: "list.bullet.rectangle") }
                CubosView()
                    .tabItem { Label("Cubos", systemImage: "cube.fill") }
                AjustesView()
                    .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
            }
            .tint(ciano)
            .environmentObject(modelo)
            .preferredColorScheme(.dark)
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        }
    }
}
