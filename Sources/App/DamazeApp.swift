import SwiftUI

@main
struct DamazeApp: App {
    @State private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
        }
    }
}
