public protocol Command {
    var id: String { get }
    var console: ConsoleProtocol { get }
    func run() throws
    func printHelp() throws
    var subcommands: [Command] { get }

    var signature: [Argument] { get }
    var help: [String] { get }
    func verifyArguments() throws
}

extension Command {
    public var signature: [Argument] {
        return []
    }
    
    public var help: [String] {
        return []
    }
    
    public var subcommands: [Command] {
        return []
    }
    
    public func printHelp() throws {
        console.info("Usage: ", newLine: false)
        console.print("\(console.executable) ", newLine: false)
        
        if subcommands.count > 0 {
            console.warning("command ", newLine: false)
        }
        
        for value in signature.values {
            console.warning("<\(value.name)> ", newLine: false)
        }
        
        for option in signature.options {
            if let shortcut = option.shortcut {
                console.success("[--\(option.name),\(shortcut)] ", newLine: false)
            } else {
                console.success("[--\(option.name)] ", newLine: false)
            }
        }
        console.print("")
        
        console.print("")
        for help in help {
            console.print(help)
        }
        console.print("")
        
        do {
            var maxWidth = 0
            for runnable in signature {
                let count = runnable.name.characters.count
                if count > maxWidth {
                    maxWidth = count
                }
            }
            
            let leadingSpace = 2
            let width = maxWidth + leadingSpace
            
            let vals = signature.flatMap { $0 as? Value }
            let opts = signature.flatMap { $0 as? Option }
            
            if signature.values.count > 0 {
                console.info("Arugments:")
                for val in vals {
                    console.print(String(
                        repeating: " ", count: width - val.name.characters.count),
                                  newLine: false
                    )
                    console.warning(val.name, newLine: false)
                    
                    if val.help.count == 0 {
                        console.print(" No description")
                    }
                    
                    for (i, help) in val.help.enumerated() {
                        console.print(" ", newLine: false)
                        if i != 0 {
                            console.print(
                                String(
                                    repeating: " ",
                                    count: width
                                ),
                                newLine: false
                            )
                        }
                        console.print(help)
                    }
                }
                console.print("")
            }
            
            if signature.options.count > 0 {
                console.info("Options:")
                for opt in opts {
                    console.print(String(
                        repeating: " ", count: width - opt.name.characters.count),
                                  newLine: false
                    )
                    console.success(opt.name, newLine: false)
                    
                    if opt.help.count == 0 {
                        console.print(" No description")
                    }
                    
                    for (i, help) in opt.help.enumerated() {
                        console.print(" ", newLine: false)
                        if i != 0 {
                            console.print(
                                String(
                                    repeating: " ",
                                    count: width
                                ),
                                newLine: false
                            )
                        }
                        console.print(help)
                    }
                }
                console.print("")
            }
        }
        
        if !subcommands.isEmpty {
            console.info("Commands:")
            
            var maxWidth = 0
            for command in subcommands {
                let count = command.id.characters.count
                if count > maxWidth {
                    maxWidth = count
                }
            }
            
            let leadingSpace = 2
            let width = maxWidth + leadingSpace
            
            for command in subcommands {
                console.print(String(
                    repeating: " ", count: width - command.id.characters.count),
                              newLine: false
                )
                console.warning(command.id, newLine: false)
                for (i, help) in command.help.enumerated() {
                    console.print(" ", newLine: false)
                    if i != 0 {
                        console.print(String(
                            repeating: " ", count: width),
                                      newLine: false
                        )
                    }
                    console.print(help)
                }
            }
            
            console.print("")
            console.print("Use `\(console.executable) ", newLine: false)
            console.warning("command", newLine: false)
            console.print(" --help` for more information on a command.")
        }
    }
}
