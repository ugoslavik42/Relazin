//
//  CyanideTweaksView.swift
//  relazin
//
//  Native tweak engine ported from cyanide — one-tap SpringBoard tweaks
//  running through the RemoteCall shim.
//

import SwiftUI

struct CyanideTweaksView: View {
    @State private var output: [String] = []
    @State private var busy = false

    var body: some View {
        ZStack {
            terminalwatermark()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    terminalsection("springboard")

                    tweakbtn("app switcher grid") { appswitchergrid_apply_in_session() }
                    tweakbtn("kill all apps") {
                        var killed: Int32 = 0
                        let ok = killallapps_apply_in_session(&killed)
                        log("killed \(killed) apps")
                        return ok
                    }
                    tweakbtn("hide home bar") { hide_home_bar_apply() }
                    tweakbtn("restore home bar") { hide_home_bar_restore() }
                    tweakbtn("disable app library") { darksword_tweak_disable_app_library_in_session() }
                    tweakbtn("disable icon fly-in") { darksword_tweak_disable_icon_fly_in_in_session() }
                    tweakbtn("zero wake animation") { darksword_tweak_zero_wake_animation_in_session() }
                    tweakbtn("zero backlight fade") { darksword_tweak_zero_backlight_fade_in_session() }
                    tweakbtn("double tap to lock") { darksword_tweak_double_tap_to_lock_in_session() }
                    tweakbtn("dock: 6 icons, grid 4x6, hide labels") {
                        sbcustomizer_apply_in_session(6, 4, 6, true)
                    }
                    tweakbtn("status bar: net + cpu") {
                        statbar_apply_in_session(false, true, true, true, false)
                    }
                    tweakbtn("status bar: stop") { statbar_stop_in_session() }
                    tweakbtn("center clock (nsbar)") { nsbar_apply_in_session(NSBarPositionCenter) }
                    tweakbtn("nsbar: stop") { nsbar_stop_in_session() }

                    terminalsection("system")

                    tweakbtn("disable ota updates") { darksword_ota_set_disabled(true) }
                    tweakbtn("enable ota updates") { darksword_ota_set_disabled(false) }
                    tweakbtn("mute call recording sound") { call_recording_sound_set_disabled(true) }
                    tweakbtn("unmute call recording sound") { call_recording_sound_set_disabled(false) }
                    tweakbtn("powercuff: heavy") { powercuff_apply("heavy") }
                    tweakbtn("powercuff: nominal") { powercuff_apply("nominal") }
                    tweakbtn("powercuff: off") { powercuff_apply("off") }

                    Text("─ note ─────────────")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(terminal.dim)
                        .padding(.top, 22)
                    Text("run the exploit first (advanced → exploit & actions).\nmost tweaks apply live; some need a respring.\nmore tweaks (live wallpaper, themer, location sim,\ngravity, nicebar, nano registry) — coming soon.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(terminal.dim)
                        .padding(.top, 6)

                    if !output.isEmpty {
                        terminalsection("output")
                        ForEach(Array(output.suffix(30).enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(line.hasPrefix("[!]") ? terminal.red : terminal.green)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("▸ cyanide tweaks")
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundColor(terminal.green)
            }
        }
        .toolbarBackground(terminal.bg, for: .navigationBar)
    }

    private func terminalsection(_ title: String) -> some View {
        Text("─ \(title) ─────────────")
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(terminal.dim)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }

    private func tweakbtn(_ title: String, action: @escaping () -> Bool) -> some View {
        Button {
            run(title, action)
        } label: {
            HStack(spacing: 10) {
                Text("▸")
                    .foregroundColor(terminal.green)
                Text(title)
                    .foregroundColor(.white)
                Spacer()
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private func run(_ title: String, _ action: @escaping () -> Bool) {
        busy = true
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = action()
            DispatchQueue.main.async {
                log("\(ok ? "[*]" : "[!]") \(title): \(ok ? "ok" : "failed")")
                busy = false
            }
        }
    }

    private func log(_ line: String) {
        output.append(line)
    }
}
