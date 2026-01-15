import SwiftUI

// MARK: - DangoApp

@main
public struct DangoApp: App {
    private let container: DIContainer
    
    public init() {
        container = DIContainer.shared
    }
    
    public var body: some Scene {
        WindowGroup {
            ContentView(
                wordListViewModel: container.wordListViewModel,
                wordDetailViewModel: container.wordDetailViewModel,
                wordEditorViewModel: container.wordEditorViewModel
            )
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("새 단어") {
                    // TODO: 새 단어 추가 액션
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
