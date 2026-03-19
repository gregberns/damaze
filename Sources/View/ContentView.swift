import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Damaze")
                .font(.largeTitle)
                .fontWeight(.bold)
                .navigationTitle("Damaze")
        }
    }
}

#Preview {
    ContentView()
}
