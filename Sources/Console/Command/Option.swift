public struct Option: Argument {
    public var name: String
    public var shortcut: String?
    public var help: [String]

    public init(name: String, shortcut: String? = nil, help: [String] = []) {
        self.name = name
        self.shortcut = shortcut
        self.help = help
    }
}


extension Command {
    public func option(_ name: String) throws -> String? {
        guard let option = signature.options.filter({ $0.name == name}).first else {
            throw "option not found"
        }
        
        guard let value = console.arguments.options[option.name] else {
            if let shortcut = option.shortcut, let value = console.arguments.options[shortcut] {
                return value
            }
            
            throw "option not supplied"
        }
        
        return value
    }
    
    
    public func flag(_ name: String) throws -> Bool {
        return try option(name)?.bool == true
    }
}


extension String: Error { }
