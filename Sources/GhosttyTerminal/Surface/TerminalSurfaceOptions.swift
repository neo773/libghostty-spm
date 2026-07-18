//
//  TerminalSurfaceOptions.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import GhosttyKit

public struct TerminalSurfaceOptions: Sendable {
    public var backend: TerminalSessionBackend
    public var fontSize: Float?
    public var workingDirectory: String?
    /// Extra environment variables set in the child process spawned for this
    /// surface (exec backend). Passed through `ghostty_surface_config_s.env_vars`;
    /// every process launched from the surface's shell inherits them, which lets
    /// embedding hosts tag a surface (e.g. `MYAPP_PANE=<uuid>`) and correlate
    /// externally observed processes back to it.
    public var envVars: [String: String]
    /// Text fed to the child process (exec backend) as stdin the moment it is
    /// spawned, via `ghostty_surface_config_s.initial_input`. Unlike typing into
    /// the surface after it renders, this is delivered by libghostty at spawn
    /// time, so it cannot race surface/render readiness. Include a trailing
    /// newline to submit a command. Ignored by the in-memory backend.
    public var initialInput: String?
    public var context: TerminalSurfaceContext

    public init(
        backend: TerminalSessionBackend = .exec,
        fontSize: Float? = nil,
        workingDirectory: String? = nil,
        envVars: [String: String] = [:],
        initialInput: String? = nil,
        context: TerminalSurfaceContext = .window
    ) {
        self.backend = backend
        self.fontSize = fontSize
        self.workingDirectory = workingDirectory
        self.envVars = envVars
        self.initialInput = initialInput
        self.context = context
    }

    func isEquivalent(to other: TerminalSurfaceOptions) -> Bool {
        fontSize == other.fontSize
            && workingDirectory == other.workingDirectory
            && envVars == other.envVars
            && initialInput == other.initialInput
            && context == other.context
            && backend.isEquivalent(to: other.backend)
    }

    var inMemorySession: InMemoryTerminalSession? {
        guard case let .inMemory(session) = backend else { return nil }
        return session
    }
}
