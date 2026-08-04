//
//  TerminalRootView.swift
//  relazin
//
//  Home screen in the terminal style from the design photo:
//  watermark background, pixel logo, auto-detected device info,
//  and the main menu.
//

import SwiftUI

struct TerminalRootView: View {
    @EnvironmentObject private var mgr: laramgr

    var body: some View {
        NavigationStack {
            ZStack {
                terminalwatermark()

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    terminallogo()
                        .padding(.bottom, 6)

                    Text("For iOS 17.0 – 18.7, 26.0 – 26.0.1")
                        .font(.system(size: 17, design: .monospaced))
                        .foregroundColor(terminal.dim)
                        .padding(.bottom, 14)

                    terminaldivider()
                        .padding(.bottom, 10)

                    terminalinforow(key: "os", value: deviceinfo.os)
                    terminalinforow(key: "host", value: deviceinfo.host)
                    terminalinforow(key: "kernel", value: deviceinfo.kernel)
                    terminalinforow(key: "build", value: deviceinfo.build)
                    terminalinforow(key: "uptime", value: deviceinfo.uptime)

                    terminaldivider()
                        .padding(.top, 10)
                        .padding(.bottom, 18)

                    Text("Tap an option below to start…")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(terminal.dim)
                        .padding(.bottom, 22)

                    terminalmenuitem(title: "Restart SpringBoard", highlighted: true) {
                        mgr.respring()
                    }

                    terminalmenuitem(title: "Restart Userspace") {
                        if let err = restartuserspace() {
                            Alertinator.shared.alert(
                                title: "Userspace reboot failed",
                                body: "\(err)\n\nRun the exploit first (Advanced Options → Exploit).",
                                actionLabel: "OK",
                                action: {}
                            )
                        }
                    }

                    NavigationLink {
                        TerminalAdvancedView()
                    } label: {
                        terminalmenulabel(title: "Advanced Options")
                    }

                    NavigationLink {
                        CreditsView()
                    } label: {
                        terminalmenulabel(title: "Credits")
                    }

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 28)
            }
            .navigationBarHidden(true)
        }
        .tint(terminal.green)
    }
}

/// NavigationLink label styled like a menu item (needs the link for push).
private struct terminalmenulabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(" ")
                .foregroundColor(terminal.green)
            Text(title)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.system(size: 22, weight: .medium, design: .monospaced))
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
