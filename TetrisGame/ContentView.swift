//
//  ContentView.swift
//  TetrisGame
//
//  Created by Gaurav Tak on 15/10/26.
//

import SwiftUI

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}

/// Home -> Game navigation (pause / game over overlays live inside GameView).
struct ContentView: View {
    enum Screen { case home, game }
    @State private var screen: Screen = .home

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch screen {
            case .home:
                HomeView(best: UserDefaults.standard.integer(forKey: "best")) {
                    withAnimation(.easeInOut(duration: 0.25)) { screen = .game }
                }
                .transition(.opacity)
            case .game:
                GameView {
                    withAnimation(.easeInOut(duration: 0.25)) { screen = .home }
                }
                .transition(.opacity)
            }
        }
    }
}


#Preview {
    ContentView()
}
