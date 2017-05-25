import libc
import Foundation

private var _pids: [pid_t] = []

public final class Terminal: ConsoleProtocol {
    public enum Error: Swift.Error {
        case cancelled
        case execute(Int)
    }

    /// Creates an instance of Terminal.
    public init() {
        func kill(sig: Int32) {
            for pid in _pids {
                _ = libc.kill(pid, sig)
            }
            exit(sig)
        }

        signal(SIGINT, kill)
        signal(SIGTERM, kill)
        signal(SIGQUIT, kill)
        signal(SIGHUP, kill)
    }

    public func stream(_ stream: ConsoleStream) -> String? {
        switch stream {
        case .clear(let clear):
            #if !Xcode
                switch clear {
                case .line:
                    command(.cursorUp)
                    command(.eraseLine)
                case .screen:
                    command(.eraseScreen)
                }
            #endif
        case .input(let secure):
            if secure {
                // http://stackoverflow.com/a/30878869/2611971
                let entry: UnsafeMutablePointer<Int8> = getpass("")
                let pointer: UnsafePointer<CChar> = .init(entry)
                guard var pass = String(validatingUTF8: pointer) else {
                    return nil
                }
                if pass.hasSuffix("\n") {
                    pass = pass.makeBytes().dropLast().makeString()
                }
                return pass
            } else {
                return readLine(strippingNewline: true)
            }
        case .output(let string, let style, let newLine):
            let terminator = newLine ? "\n" : ""
            
            let output: String
            if let color = style.terminalColor {
                #if !Xcode
                    output = string.terminalColorize(color)
                #else
                    output = string
                #endif
            } else {
                output = string
            }
            
            Swift.print(output, terminator: terminator)
            fflush(stdout)
        case .error(let error, let newLine):
            let output = newLine ? error + "\n" : error
            
            guard let data = output.data(using: .utf8) else {
                return nil
            }
            
            FileHandle.standardError.write(data)
        }
        
        return nil
    }


    public func execute(
        program: String,
        arguments: [String],
        input: ExecuteStream? = nil,
        output: ExecuteStream? = nil,
        error: ExecuteStream? = nil
    ) throws {
        var program = program
        if !program.hasPrefix("/") {
            let res = try backgroundExecute(program: "/bin/sh", arguments: ["-c", "which \(program)"])
            program = res.makeString().trim()
        }
        // print(program + " " + arguments.joined(separator: " "))
        let process = Process()
        process.environment = ProcessInfo.processInfo.environment
        process.launchPath = program
        process.arguments = arguments
        process.standardInput = input?.either
        process.standardOutput = output?.either
        process.standardError = error?.either
        process.qualityOfService = .userInteractive
        
        process.launch()
        _pids.append(process.processIdentifier)
        
        process.waitUntilExit()
        let status = process.terminationStatus
        
        if status != 0 {
            throw ConsoleError.execute(code: Int(status))
        }
    }

    public var confirmOverride: Bool? {
        if arguments.contains("-y") {
            return true
        } else if arguments.contains("-n") {
            return false
        }

        return nil
    }

    public var size: (width: Int, height: Int) {
        var w = winsize()
        _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w);
        return (Int(w.ws_col), Int(w.ws_row))
    }

    /**
        Runs an ansi coded command.
    */
    private func command(_ command: Command) {
        output(command.ansi, newLine: false)
    }
    
    public var extend: [String: Any] = [:]
}
