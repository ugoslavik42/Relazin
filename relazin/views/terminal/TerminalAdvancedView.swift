//
//  TerminalAdvancedView.swift
//  relazin
//
//  "Advanced Options" — terminal-styled hub into the full feature set
//  inherited from lara plus the tweak engine from cyanide.
//

import SwiftUI

struct TerminalAdvancedView: View {
    @EnvironmentObject private var mgr: laramgr

    var body: some View {
        ZStack {
            terminalwatermark()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    terminalsectionheader("core")

                    terminalnavlink("Exploit & Actions", subtitle: "run darksword, krw, remotecall") {
                        ContentView()
                    }

                    terminalsectionheader("tweaks")

                    terminalnavlink("Built-in Tweaks", subtitle: "fonts, dock, status bar, gestalt…") {
                        TweaksView(mgr: mgr)
                    }

                    terminalnavlink("Cyanide Tweaks", subtitle: "springboard & system tweaks engine") {
                        CyanideTweaksView()
                    }

                    terminalnavlink("Load Custom Tweak", subtitle: "run .js / inject .dylib — no rebuild") {
                        CustomTweakLoaderView()
                    }

                    terminalsectionheader("system")

                    terminalnavlink("File Manager", subtitle: "full disk r/w") {
                        SantanderView(startPath: "/")
                    }

                    terminalnavlink("Settings") {
                        SettingsView()
                    }

                    terminalnavlink("Logs") {
                        LogsView(logger: globallogger)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("▸ advanced options")
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundColor(terminal.green)
            }
        }
        .toolbarBackground(terminal.bg, for: .navigationBar)
    }
}

private struct terminalsectionheader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text("─ \(title) ─────────────")
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(terminal.dim)
            .padding(.top, 22)
            .padding(.bottom, 8)
            .lineLimit(1)
    }
}

private struct terminalnavlink<Destination: View>: View {
    let title: String
    let subtitle: String?
    let destination: Destination

    init(_ title: String, subtitle: String? = nil, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.subtitle = subtitle
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 10) {
                    Text("▸")
                        .foregroundColor(terminal.green)
                    Text(title)
                        .foregroundColor(.white)
                    Spacer()
                }
                .font(.system(size: 19, weight: .medium, design: .monospaced))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(terminal.dim)
                        .padding(.leading, 24)
                }
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
    }
}
