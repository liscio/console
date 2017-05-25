extension ConsoleProtocol {
    /// Runs a group of commands.
    ///
    /// The first argument should be the name of the
    /// currently executing program.
    ///
    /// The second argument should be the id of the command
    /// that should run. Identifiers can recurse through groups.
    ///
    /// Following arguments and options will be passed through
    /// to the commands.
    public func run(_ command: Command, arguments a: [String]) throws {
        var command = command
        self.arguments = a
        
        // get out all special args
        if arguments.contains("-y") {
            confirmOverride = true
            arguments.remove("-y")
        }
        
        if arguments.contains("-n") {
            confirmOverride = false
            arguments.remove("-n")
        }
        
        if arguments.contains("--verbose") {
            isVerbose = true
            arguments.remove("--verbose")
        }
        
        if arguments.contains("-vv") {
            isVerbose = true
            arguments.remove("-vv")
        }
        
        let isHelp: Bool
        if arguments.contains("--help") {
            isHelp = true
            arguments.remove("--help")
        } else {
            isHelp = false
        }
        
        // start command
        valueOffset = 0
        
        executable = command.id
        while !command.subcommands.isEmpty {
            if let name = try popValue() {
                if let found = command.subcommands.filter({ $0.id == name }).first {
                    command = found
                    executable = executable + " " + command.id
                } else {
                    arguments.append(name)
                    break
                }
            } else {
                break
            }
        }
        
        if isHelp {
            try command.printHelp()
        } else {
            try command.verifyArguments()
            try command.run()
        }
        
        /*let isHelp = arguments.flag("help")

        var commands = group.commands
        var executable = group.id
        var foundCommand: Command? = nil

        while foundCommand == nil {
            guard let id = try popValue() else {
                // no command and no more values
                if isHelp {
                    // group help was requested
                    printHelp(executable: executable, group: group)
                    throw ConsoleError.help
                } else if let fallback = group.fallback {
                    foundCommand = fallback
                    break
                } else {
                    // cannot run groups
                    throw ConsoleError.noCommand
                }
            }

            guard let runnable = commands.filter({ $0.id == id }).first else {
                // value doesn't match any runnable items
                printHelp(executable: executable, group: group)
                throw ConsoleError.commandNotFound(id)
            }

            if let command = runnable as? Command {
                // got a command
                foundCommand = command
            } else if let g = runnable as? Group {
                // got a group of commands
                commands = g.commands
                executable = "\(executable) \(g.id)"
                group = g
            }
        }

        guard let command = foundCommand else {
            // no command was given
            throw ConsoleError.noCommand
        }

        if isHelp {
            // command help was requested
            printHelp(executable: executable, command: command)
            throw ConsoleError.help
        } else {
            // calculate number of values passed
            let valueCount = arguments.values.count - valueOffset
            
            // verify there are enough values to satisfy the signature
            if valueCount != command.signature.values.count {
                command.printUsage(executable: executable)
                throw "invalid argument count"
            }

            // pass through options
            let commandOptions = command.signature.options.map({ $0.name })
            for option in arguments.options {
                guard commandOptions.contains(option.key) else {
                    throw "invalid option: \(option.key)"
                }
            }

            try command.run()
        }*/
    }
}

/*public final class Group: Command {
    public let id: String
    public let signature: [Argument]
    public let help: [String]
    public let console: ConsoleProtocol
    public let subcommands: [Command]
    public let fallback: Command?
    
    public init(
        id: String,
        help: [String],
        _ console: ConsoleProtocol,
        _ subcommands: [Command],
        fallback: Command? = nil
    ) {
        self.id = id
        self.signature = []
        self.help = help
        self.console = console
        self.subcommands = subcommands
        self.fallback = fallback
    }
    
    public func run() throws {
        guard let command = try findCommand() else {
            throw "insufficient arguments"
        }
        try command.verifyArguments()
        try command.run()
    }
    
    
    public func verifyArguments() throws {
        // anything goes...
    }
    
    private func findCommand() throws -> Command? {
        guard let name = try console.popValue() else {
            return nil
        }
        
        guard let command = subcommands.filter({ $0.id == name }).first else {
            throw "No command with that name found"
        }
        
        return command
    }
}*/

extension Command {
    public func verifyArguments() throws {
        // calculate number of values passed
        let valueCount = console.arguments.values.count - console.valueOffset
        
        // verify there are enough values to satisfy the signature
        if valueCount != signature.values.count {
            // console.printUsage()
            throw "invalid argument count"
        }
        
        let commandOptions = signature.options.map({ $0.name })
            + signature.options.flatMap({ $0.shortcut })
        
        for option in console.arguments.options {
            guard commandOptions.contains(option.key) else {
                throw "invalid option: \(option.key)"
            }
        }
    }
}

extension ConsoleProtocol {
    var confirmOverride: Bool? {
        get { return extend["confirmOverride"] as? Bool }
        set { extend["confirmOverride"] = newValue }
    }
}

extension ConsoleProtocol {
    var isVerbose: Bool {
        get { return extend["isVerbose"] as? Bool ?? false }
        set { extend["isVerbose"] = newValue }
    }
}

extension ConsoleProtocol {
    var executable: String {
        get { return extend["executable"] as? String ?? "" }
        set { extend["executable"] = newValue }
    }
}

extension ConsoleProtocol {
    var arguments: [String] {
        get { return extend["arguments"] as? [String] ?? [] }
        set { extend["arguments"] = newValue }
    }
}


extension Array where Iterator.Element == String {
    mutating func remove(_ string: String) {
        if let index = index(of: string) {
            remove(at: index)
        }
    }
}

extension ConsoleProtocol {
    func popValue() throws -> String? {
        guard arguments.values.count > valueOffset else {
            return nil
        }
        
        let value = arguments.values[valueOffset]
        valueOffset += 1
        return value
    }
    
    var valueOffset: Int {
        get { return extend["valueOffset"] as? Int ?? 0 }
        set { extend["valueOffset"] = newValue }
    }
}

