//
//  TerminalSurfaceView.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import SwiftUI

public struct TerminalSurfaceView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var context: TerminalViewState
    let focusBinding: TerminalFocusBinding?
    let isVisible: Bool
    let shouldFocus: Bool

    public init(context: TerminalViewState) {
        self.context = context
        focusBinding = nil
        isVisible = true
        shouldFocus = false
    }

    init(
        context: TerminalViewState,
        focusBinding: TerminalFocusBinding?,
        isVisible: Bool = true,
        shouldFocus: Bool = false
    ) {
        self.context = context
        self.focusBinding = focusBinding
        self.isVisible = isVisible
        self.shouldFocus = shouldFocus
    }

    public var body: some View {
        TerminalViewRepresentable(
            context: context,
            controller: context.controller,
            configuration: context.configuration,
            focusBinding: focusBinding,
            isVisible: isVisible,
            shouldFocus: shouldFocus
        )
        .background(.clear)
        .onChange(of: colorScheme) { newScheme in
            context.adopt(colorScheme: newScheme)
        }
        .onAppear {
            context.adopt(colorScheme: colorScheme)
        }
    }

    public func terminalFocused(
        _ condition: FocusState<Bool>.Binding
    ) -> TerminalSurfaceView {
        TerminalSurfaceView(
            context: context,
            focusBinding: .bool(condition),
            isVisible: isVisible,
            shouldFocus: shouldFocus
        )
    }

    public func terminalFocused<Value: Hashable>(
        _ binding: FocusState<Value?>.Binding,
        equals value: Value
    ) -> TerminalSurfaceView {
        TerminalSurfaceView(
            context: context,
            focusBinding: .optional(binding, equals: value),
            isVisible: isVisible,
            shouldFocus: shouldFocus
        )
    }

    /// Controls whether the surface renders. Pass `false` for off-screen panes (hidden
    /// tab / workspace) to stop rendering while keeping the PTY and its process alive;
    /// pass `true` to resume. Independent of focus.
    public func terminalVisible(_ visible: Bool) -> TerminalSurfaceView {
        TerminalSurfaceView(
            context: context,
            focusBinding: focusBinding,
            isVisible: visible,
            shouldFocus: shouldFocus
        )
    }

    /// Drives keyboard focus from the host's own active-pane state. Pass `true` for the
    /// active pane; the terminal view becomes AppKit first responder (with async retry
    /// while it attaches to its window). This is the reliable path — SwiftUI `@FocusState`
    /// does not reach a wrapped NSView.
    public func terminalShouldFocus(_ shouldFocus: Bool) -> TerminalSurfaceView {
        TerminalSurfaceView(
            context: context,
            focusBinding: focusBinding,
            isVisible: isVisible,
            shouldFocus: shouldFocus
        )
    }

    public func terminalFocusOnAppear(
        _ condition: FocusState<Bool>.Binding
    ) -> some View {
        terminalFocused(condition)
            .onAppear {
                condition.wrappedValue = true
            }
    }

    public func terminalFocusOnAppear<Value: Hashable>(
        _ binding: FocusState<Value?>.Binding,
        equals value: Value
    ) -> some View {
        terminalFocused(binding, equals: value)
            .onAppear {
                binding.wrappedValue = value
            }
    }
}
