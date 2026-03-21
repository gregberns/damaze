import SwiftUI

@main
struct DamazeApp: App {
    @State private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.isShowingLevelSelect {
                LevelSelectView(onSelectLevel: viewModel.selectLevel)
                    .transition(.opacity)
            } else {
                GameView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
    }
}
