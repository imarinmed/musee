//
//  MuseeUI.swift
//  MuseeUI
//
//  Shared SwiftUI components for museum applications.
//  Platform-agnostic UI building blocks that work across all Apple platforms.
//
//  Usage:
//  ```
//  import MuseeUI
//
//  struct MyView: View {
//      var body: some View {
//          MuseumCard {
//              Text("Artwork Title")
//          }
//      }
//  }
//  ```
//

import SwiftUI

/// Shared SwiftUI components for museum applications
public struct MuseeUI {
    public init() {}
}

/// A card-style container for museum content
public struct MuseumCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .shadow(radius: 2)

            content
                .padding()
        }
        .frame(maxWidth: .infinity)
    }
}

/// A loading indicator for museum operations
public struct MuseumLoadingView: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.accentColor, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }

            Text("Analyzing beauty...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// A search bar component for museum applications
public struct MuseumSearchBar: View {
    @Binding var text: String
    let placeholder: String

    public init(text: Binding<String>, placeholder: String = "Search museum...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(8)
    }
}