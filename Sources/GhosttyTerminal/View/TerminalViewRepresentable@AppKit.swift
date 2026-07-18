//
//  TerminalViewRepresentable@AppKit.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

#if canImport(AppKit) && !canImport(UIKit)
    import AppKit
    import SwiftUI

    extension TerminalViewRepresentable: NSViewRepresentable {
        func makeNSView(context _: Context) -> TerminalView {
            let view = TerminalView(frame: .zero)
            configureView(view, initial: true)
            view.onFocusChange = { focused in
                focusBinding.setFocused(focused)
            }
            // Focus intent comes from the host's active-pane state, not the SwiftUI focus
            // binding — the latter never routes into a wrapped NSView, so it always read
            // false and the terminal never became first responder without a click.
            view.focusIntent = { [shouldFocus] in shouldFocus }
            view.setSurfaceVisible(isVisible)
            view.requestFocusIfIntended()
            return view
        }

        func updateNSView(_ view: TerminalView, context _: Context) {
            configureView(view, initial: false)
            view.onFocusChange = { focused in
                focusBinding.setFocused(focused)
            }
            view.focusIntent = { [shouldFocus] in shouldFocus }
            view.setSurfaceVisible(isVisible)
            view.requestFocusIfIntended()
        }

        static func dismantleNSView(_ view: TerminalView, coordinator _: ()) {
            view.onFocusChange = nil
        }
    }
#endif
