#!/usr/bin/env swift
import AppKit
import Foundation
import UniformTypeIdentifiers

/// Strips Office "picture fallback" types from Word text copies on the general pasteboard.
/// Keeps plain text / RTF / HTML. Leaves real image copies and non-Word sources alone.

private let logURL = URL(fileURLWithPath: NSHomeDirectory())
    .appendingPathComponent("Library/Logs/WordClipboardFix.log")

private let pollInterval: TimeInterval = 0.15
private let maxLogBytes: UInt64 = 256 * 1024

private let knownImageTypeStrings: Set<String> = [
    "public.png",
    "public.tiff",
    "public.jpeg",
    "public.jpeg-2000",
    "public.jpg",
    "com.adobe.pdf",
    "com.apple.pict",
    "public.heic",
    "public.heif",
    "NeXT TIFF v4.0 pasteboard type",
    "Apple PICT pasteboard type",
    "Apple PDF pasteboard type",
    "Apple PNG pasteboard type"
]

private let wordHTMLMarkers = [
    "urn:schemas-microsoft-com:office:word",
    "schemas-microsoft-com:office:word",
    "xmlns:w=\"urn:schemas-microsoft-com:office:word\"",
    "ProgId=\"Word.Document",
    "generator Microsoft Word",
    "<!--[if gte mso"
]

private let wordRTFMarkers = [
    "{\\*\\generator Microsoft Word",
    "\\generator Microsoft Word",
    "Microsoft Word "
]

private func log(_ message: String) {
    let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
    let data = Data(line.utf8)
    if FileManager.default.fileExists(atPath: logURL.path) {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logURL.path),
           let size = attrs[.size] as? UInt64, size > maxLogBytes {
            try? data.write(to: logURL)
        } else if let handle = try? FileHandle(forWritingTo: logURL) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    } else {
        try? data.write(to: logURL)
    }
}

private func string(from pb: NSPasteboard, type: NSPasteboard.PasteboardType) -> String? {
    if let s = pb.string(forType: type), !s.isEmpty { return s }
    guard let data = pb.data(forType: type), !data.isEmpty else { return nil }
    return String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .utf16)
        ?? String(data: data, encoding: .macOSRoman)
}

private func plainText(from pb: NSPasteboard) -> String? {
    let candidates: [NSPasteboard.PasteboardType] = [
        .string,
        NSPasteboard.PasteboardType("public.utf8-plain-text"),
        NSPasteboard.PasteboardType("public.utf16-external-plain-text"),
        NSPasteboard.PasteboardType("NSStringPboardType")
    ]
    for t in candidates {
        if let s = string(from: pb, type: t)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty {
            return s
        }
    }
    return nil
}

private func htmlPayload(from pb: NSPasteboard) -> String? {
    let candidates: [NSPasteboard.PasteboardType] = [
        .html,
        NSPasteboard.PasteboardType("public.html"),
        NSPasteboard.PasteboardType("Apple HTML pasteboard type")
    ]
    for t in candidates {
        if let s = string(from: pb, type: t), !s.isEmpty { return s }
    }
    return nil
}

private func rtfPayload(from pb: NSPasteboard) -> String? {
    let candidates: [NSPasteboard.PasteboardType] = [
        .rtf,
        NSPasteboard.PasteboardType("public.rtf"),
        NSPasteboard.PasteboardType("NeXT Rich Text Format v1.0 pasteboard type")
    ]
    for t in candidates {
        if let s = string(from: pb, type: t), !s.isEmpty { return s }
    }
    return nil
}

private func isFromMicrosoftWord(_ pb: NSPasteboard) -> Bool {
    let sourceTypes: [NSPasteboard.PasteboardType] = [
        NSPasteboard.PasteboardType("org.nspasteboard.source"),
        NSPasteboard.PasteboardType("org.nspasteboard.source-app"),
        NSPasteboard.PasteboardType("com.apple.pasteboard.source")
    ]
    for t in sourceTypes {
        if let source = string(from: pb, type: t)?.lowercased() {
            if source.contains("com.microsoft.word")
                || source.contains("microsoft word")
                || source.contains("microsoftword") {
                return true
            }
        }
    }

    if let html = htmlPayload(from: pb)?.lowercased() {
        for marker in wordHTMLMarkers {
            if html.contains(marker.lowercased()) { return true }
        }
        // Office HTML often carries mso / Word class markers even when namespace is truncated.
        if html.contains("mso-") && html.contains("word") { return true }
    }

    if let rtf = rtfPayload(from: pb) {
        for marker in wordRTFMarkers {
            if rtf.contains(marker) { return true }
        }
    }

    return false
}

private func isImageOrPDFType(_ type: NSPasteboard.PasteboardType) -> Bool {
    let raw = type.rawValue
    if knownImageTypeStrings.contains(raw) { return true }
    let lowered = raw.lowercased()
    if lowered.contains("png") || lowered.contains("tiff") || lowered.contains("jpeg")
        || lowered.contains("jpg") || lowered.contains("pdf") || lowered.contains("pict") {
        // Avoid stripping text-ish types that merely mention those words.
        if lowered.contains("text") || lowered.contains("html") || lowered.contains("rtf")
            || lowered.contains("url") || lowered.contains("file-url") {
            return false
        }
        return true
    }
    if let ut = UTType(raw) {
        if ut.conforms(to: .image) || ut.conforms(to: .pdf) { return true }
    }
    return false
}

private func availableTypes(_ pb: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    pb.types ?? []
}

private func hasImageOrPDF(_ pb: NSPasteboard) -> Bool {
    availableTypes(pb).contains { isImageOrPDFType($0) }
}

@discardableResult
private func stripImageTypes(from pb: NSPasteboard) -> Bool {
    let types = availableTypes(pb)
    let keep = types.filter { !isImageOrPDFType($0) }
    let remove = types.filter { isImageOrPDFType($0) }
    guard !remove.isEmpty, !keep.isEmpty else { return false }

    var preserved: [(NSPasteboard.PasteboardType, Data)] = []
    for t in keep {
        if let data = pb.data(forType: t) {
            preserved.append((t, data))
        } else if let s = pb.string(forType: t), let data = s.data(using: .utf8) {
            preserved.append((t, data))
        }
    }
    guard !preserved.isEmpty else { return false }

    pb.clearContents()
    for (t, data) in preserved {
        pb.setData(data, forType: t)
    }
    log("stripped \(remove.map(\.rawValue).joined(separator: ",")) kept \(preserved.map(\.0.rawValue).joined(separator: ","))")
    return true
}

final class PasteboardWatcher {
    private var lastSeenChangeCount: Int = NSPasteboard.general.changeCount
    private var ignoreChangeCount: Int?

    func tick() {
        let pb = NSPasteboard.general
        let cc = pb.changeCount
        if cc == lastSeenChangeCount { return }
        lastSeenChangeCount = cc

        if let ignore = ignoreChangeCount, cc == ignore {
            ignoreChangeCount = nil
            return
        }

        guard plainText(from: pb) != nil else { return }
        guard hasImageOrPDF(pb) else { return }
        guard isFromMicrosoftWord(pb) else { return }

        if stripImageTypes(from: pb) {
            ignoreChangeCount = pb.changeCount
            lastSeenChangeCount = pb.changeCount
        }
    }
}

log("WordClipboardFix starting pid=\(ProcessInfo.processInfo.processIdentifier)")
let watcher = PasteboardWatcher()
let timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
    watcher.tick()
}
RunLoop.main.add(timer, forMode: .common)
RunLoop.main.run()
