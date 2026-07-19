//
//  AppTerminalView+DragDrop.swift
//  libghostty-spm
//
//  Finder / text drag-and-drop into the terminal. Mirrors Ghostty's own
//  macOS app: dropped file URLs are inserted as shell-escaped POSIX paths,
//  plain strings pass through as-is, multiple items are space-joined. The
//  text is written to the pty via `sendText` — the same path a paste takes.
//

#if canImport(AppKit) && !canImport(UIKit)
    import AppKit

    extension AppTerminalView {
        private static let dropTypes: Set<NSPasteboard.PasteboardType> = [.string, .fileURL]

        override open func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
            guard sender.draggingPasteboard.canReadObject(
                forClasses: [NSURL.self, NSString.self],
                options: nil
            ) else {
                return []
            }
            return .copy
        }

        override open func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
            guard let content = Self.droppedText(from: sender.draggingPasteboard),
                  !content.isEmpty
            else {
                return false
            }
            // Match Ghostty: deliver on the main queue through the normal text path.
            DispatchQueue.main.async { [weak self] in
                self?.sendText(content)
            }
            return true
        }

        /// Build the string to insert for a drop: each file URL becomes a
        /// shell-escaped POSIX path, each plain string is used verbatim, and
        /// the pieces are joined with a single space (no surrounding quotes,
        /// no trailing space) — identical to Ghostty's behavior.
        private static func droppedText(from pasteboard: NSPasteboard) -> String? {
            if let urls = pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL], !urls.isEmpty {
                return urls
                    .map { shellEscape($0.path) }
                    .joined(separator: " ")
            }
            if let strings = pasteboard.readObjects(
                forClasses: [NSString.self],
                options: nil
            ) as? [String], !strings.isEmpty {
                return strings.joined(separator: " ")
            }
            return nil
        }

        /// Backslash-escape the characters a POSIX shell would otherwise
        /// interpret. Matches Ghostty's `Shell.escape`.
        private static func shellEscape(_ path: String) -> String {
            let special: Set<Character> = [
                "\\", " ", "(", ")", "[", "]", "{", "}", "<", ">",
                "\"", "'", "`", "!", "#", "$", "&", ";", "|", "*", "?", "\t",
            ]
            var result = ""
            result.reserveCapacity(path.count)
            for character in path {
                if special.contains(character) {
                    result.append("\\")
                }
                result.append(character)
            }
            return result
        }
    }
#endif
