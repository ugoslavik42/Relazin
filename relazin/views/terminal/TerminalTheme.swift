//
//  TerminalTheme.swift
//  relazin
//
//  Shared pieces of the terminal look: colors, watermark background,
//  pixel logo, info rows and menu items.
//

import SwiftUI

enum terminal {
    static let bg = Color.black
    static let green = Color(red: 0.35, green: 0.95, blue: 0.45)
    static let dim = Color(white: 0.55)
    static let red = Color(red: 1.0, green: 0.25, blue: 0.2)
    static let mono: Font = .system(.body, design: .monospaced)
}

// MARK: - Watermark background ("relazin" tiled, like the design photo)

struct terminalwatermark: View {
    var body: some View {
        Canvas { ctx, size in
            let mark = Text("relazin")
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundColor(terminal.green.opacity(0.13))
            let resolved = ctx.resolve(mark)
            let stepX: CGFloat = 150
            let stepY: CGFloat = 46
            var row = 0
            var y: CGFloat = -20
            while y < size.height + 40 {
                // stagger every other row, like the photo
                var x: CGFloat = (row % 2 == 0) ? -30 : -105
                while x < size.width + 120 {
                    ctx.draw(resolved, at: CGPoint(x: x, y: y))
                    x += stepX
                }
                y += stepY
                row += 1
            }
        }
        .background(terminal.bg)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Pixel logo: RELAZIN + red dot

struct terminallogo: View {
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("RELAZIN")
                .font(.system(size: 56, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Rectangle()
                .fill(terminal.red)
                .frame(width: 13, height: 13)
                .offset(y: -4)
        }
        .accessibilityLabel("relazin")
    }
}

// MARK: - One info row:  "os        iOS 17.0"

struct terminalinforow: View {
    let key: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text(key)
                .foregroundColor(terminal.green)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.system(size: 17, design: .monospaced))
    }
}

// MARK: - Menu item (tap = action)

struct terminalmenuitem: View {
    let title: String
    var highlighted: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Haptic.shared.play(.light)
            action()
        }) {
            HStack(spacing: 10) {
                Text(highlighted || pressed ? "▸" : " ")
                    .foregroundColor(terminal.green)
                Text(title)
                    .foregroundColor(highlighted || pressed ? terminal.green : .white)
                Spacer()
            }
            .font(.system(size: 22, weight: .medium, design: .monospaced))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .padding(.vertical, 6)
    }
}

// MARK: - Thin divider like on the photo

struct terminaldivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(height: 1)
    }
}
