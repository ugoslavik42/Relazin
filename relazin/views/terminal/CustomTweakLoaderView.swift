//
//  CustomTweakLoaderView.swift
//  relazin
//
//  Load custom tweaks at runtime — no IPA rebuild:
//   • drop .js / .dylib into Files → On My iPhone → relazin → tweaks/
//   • or pick any file with the system picker
//   • .js runs in the JS engine, .dylib gets injected into SpringBoard
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomTweakLoaderView: View {
    @EnvironmentObject private var mgr: laramgr

    @State private var tweaks: [URL] = []
    @State private var output: [String] = []
    @State private var showPicker = false
    @State private var busy = false

    /// Files → On My iPhone → relazin → tweaks
    private var tweaksDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tweaks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    var body: some View {
        ZStack {
            terminalwatermark()

            VStack(alignment: .leading, spacing: 0) {
                statusline
                    .padding(.bottom, 10)

                Text("─ tweaks ─────────────")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(terminal.dim)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if tweaks.isEmpty {
                            Text("no tweaks found.\n\ndrop .js or .dylib files into\nFiles → On My iPhone → relazin → tweaks/\nor tap [ pick file ] below.")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(terminal.dim)
                                .padding(.vertical, 14)
                        } else {
                            ForEach(tweaks, id: \.self) { url in
                                tweakrow(url)
                            }
                        }
                    }
                }

                Button {
                    showPicker = true
                } label: {
                    Text("[ pick file ]")
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundColor(terminal.green)
                }
                .padding(.vertical, 10)

                Text("─ output ─────────────")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(terminal.dim)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(output.enumerated()), id: \.offset) { i, line in
                                Text(line)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(line.hasPrefix("[!]") ? terminal.red : terminal.green)
                                    .id(i)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: output.count) { _ in
                        if let last = output.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("▸ custom tweaks")
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundColor(terminal.green)
            }
        }
        .toolbarBackground(terminal.bg, for: .navigationBar)
        .onAppear(perform: reload)
        .fileImporter(isPresented: $showPicker, allowedContentTypes: pickerTypes, allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            importFile(url)
        }
    }

    private var statusline: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tweakengine.isReady ? terminal.green : terminal.red)
                .frame(width: 8, height: 8)
            Text(tweakengine.isReady ? "remotecall ready" : "remotecall not ready — run exploit first")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(terminal.dim)
        }
    }

    private func tweakrow(_ url: URL) -> some View {
        let isDylib = url.pathExtension.lowercased() == "dylib"
        return Button {
            run(url)
        } label: {
            HStack(spacing: 10) {
                Text("▸")
                    .foregroundColor(terminal.green)
                Text(url.lastPathComponent)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(isDylib ? "inject" : "run")
                    .foregroundColor(terminal.dim)
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private var pickerTypes: [UTType] {
        var types: [UTType] = [.javaScript, .data, .text]
        if let dylib = UTType(filenameExtension: "dylib") { types.append(dylib) }
        return types
    }

    private func reload() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: tweaksDir,
            includingPropertiesForKeys: nil
        )) ?? []
        tweaks = files.filter {
            ["js", "dylib"].contains($0.pathExtension.lowercased())
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func importFile(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let dest = tweaksDir.appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
            log("[*] imported \(url.lastPathComponent)")
            reload()
        } catch {
            log("[!] import failed: \(error.localizedDescription)")
        }
    }

    private func run(_ url: URL) {
        busy = true
        let isDylib = url.pathExtension.lowercased() == "dylib"
        DispatchQueue.global(qos: .userInitiated).async {
            if isDylib {
                let result = tweakengine.injectDylib(at: url.path)
                DispatchQueue.main.async {
                    log(result.ok ? "[*] \(url.lastPathComponent): \(result.detail)"
                                  : "[!] \(url.lastPathComponent): \(result.detail)")
                    busy = false
                }
            } else {
                guard let source = try? String(contentsOf: url, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        log("[!] could not read \(url.lastPathComponent)")
                        busy = false
                    }
                    return
                }
                tweakengine.runJS(source: source) { line in
                    DispatchQueue.main.async { log(line) }
                }
                DispatchQueue.main.async { busy = false }
            }
        }
    }

    private func log(_ line: String) {
        output.append(line)
    }
}
