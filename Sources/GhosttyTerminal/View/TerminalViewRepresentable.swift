//
//  TerminalViewRepresentable.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import SwiftUI
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

@MainActor
struct TerminalViewRepresentable {
    let context: TerminalViewState
    let controller: TerminalController
    let configuration: TerminalSurfaceOptions
    let focusBinding: TerminalFocusBinding?
    /// When false the surface is marked occluded and its display link stopped, so an
    /// off-screen pane (hidden tab / workspace) stops rendering while its PTY keeps
    /// running. Defaults to true so callers that don't opt in are unaffected.
    var isVisible: Bool = true
    /// Whether this pane should hold keyboard focus, driven by the host's own active-pane
    /// state (not SwiftUI `@FocusState`, which does not reach a wrapped NSView). Drives an
    /// AppKit `makeFirstResponder` on the terminal view — the pattern upstream Ghostty uses.
    var shouldFocus: Bool = false

    func configureView(_ view: TerminalView, initial: Bool) {
        if initial {
            view.delegate = context
        }

        if let currentController = view.controller, currentController === controller {
            // Keep the current surface.
        } else {
            view.controller = controller
        }

        if !view.configuration.isEquivalent(to: configuration) {
            view.configuration = configuration
        }
    }

    static func synchronizeFocus(_ view: TerminalView, with binding: TerminalFocusBinding?) {
        guard let binding else { return }

        DispatchQueue.main.async { [weak view] in
            #if canImport(UIKit)
                guard let view, view.window != nil else { return }
                if binding.isFocused {
                    if !view.isFirstResponder { view.becomeFirstResponder() }
                } else if view.isFirstResponder {
                    _ = view.resignFirstResponder()
                }
            #elseif canImport(AppKit)
                guard let view, let window = view.window else { return }
                if binding.isFocused {
                    if window.firstResponder !== view {
                        window.makeFirstResponder(view)
                    }
                } else if window.firstResponder === view {
                    window.makeFirstResponder(nil)
                }
            #endif
        }
    }
}

@MainActor
struct TerminalFocusBinding {
    private let read: () -> Bool
    private let write: (Bool) -> Void

    var isFocused: Bool {
        read()
    }

    func setFocused(_ focused: Bool) {
        write(focused)
    }

    static func bool(_ binding: FocusState<Bool>.Binding) -> TerminalFocusBinding {
        TerminalFocusBinding(
            read: { binding.wrappedValue },
            write: { binding.wrappedValue = $0 }
        )
    }

    static func optional<Value: Hashable>(
        _ binding: FocusState<Value?>.Binding,
        equals value: Value
    ) -> TerminalFocusBinding {
        TerminalFocusBinding(
            read: { binding.wrappedValue == value },
            write: { focused in
                binding.wrappedValue = focused ? value : nil
            }
        )
    }
}

@MainActor
extension TerminalFocusBinding? {
    func setFocused(_ focused: Bool) {
        guard let binding = self, binding.isFocused != focused else {
            return
        }
        binding.setFocused(focused)
    }
}
