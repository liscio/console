/// Raw input for commands. Use this to parse options and arguments for the command context.
public struct CommandInput {
    /// The `CommandInput`'s raw arguments. This array will be mutated as arguments and options
    /// are parsed from the `CommandInput`.
    public var arguments: [String]

    /// The current executable path.
    public var executablePath: [String]

    /// Create a new `CommandInput`.
    public init(arguments: [String]) {
        precondition(arguments.count >= 1, "At least one argument (the executable path) is required")
        var arguments = arguments
        executablePath = [arguments.popFirst()!]
        self.arguments = arguments
    }

    /// Parses the option from input, returning `nil` if it could
    /// not be found or throwing an error if invalid input is detected.
    ///
    ///     var input = CommandInput(arguments: ["exec", "--foo", "bar", "baz"])
    ///     print(input.arguments) // ["--foo", "bar", "baz"]
    ///     let foo = try input.parse(option: .value(name: "foo")
    ///     print(foo) // Optional("bar")
    ///     print(input.arguments) // ["baz"]
    ///
    /// - parameters:
    ///     - option: The `CommandOption` to parse from this `CommandInput`.
    public mutating func parse(option: AnyOption) throws -> String? {
        // create a temporary [String?] array so it's
        // easier to mark positions as "consumed"
        var arguments = self.arguments.map { $0 as String? }
        defer { self.arguments = arguments.compactMap { $0 } }

        for (i, arg) in arguments.enumerated() {
            guard var arg = arg else { continue }

            var deprecatedFlagFormat = false

            if arg.hasPrefix("--\(option.name)=") {
                // deprecated option support
                print("[Deprecated] --option=value syntax is deprecated. Please use --option value (with no =) instead.")
                deprecatedFlagFormat = true
                
                // remove this option from the command input
                arguments[i] = nil
            } else if arg.hasPrefix("--") {
                // check if option matches
                guard arg == "--\(option.name)" else {
                    continue
                }

                // remove this option from the command input
                arguments[i] = nil
            } else if let short = option.short, arg.hasPrefix("-") {
                // has `-` prefix but not `--`
                if case .value = option.optionType {
                    // If we want to extract a _value_, the argument should match exactly, and the desired value will be
                    // the following argument.
                    guard arg == "-\(short)" else {
                        continue
                    }
                    
                    // remove this option from the command input
                    arguments[i] = nil
                } else {
                    // If we want extract a flag, it just needs to be anywhere in the option string to match.
                    guard let index = arg.firstIndex(of: short) else {
                        continue
                    }
                    
                    // remove this option and update the args
                    _ = arg.remove(at: index)
                    arguments[i] = arg
                    
                    if arg.count == 1 {
                        // if just the `-` left, remove this arg
                        arguments[i] = nil
                    }
                }
            } else {
                // not an option
                continue
            }

            // if we reach here, the option was found
            switch option.optionType {
            case .flag: return "true"
            case .value(let d):
                let supplied: String?

                if deprecatedFlagFormat {
                    // parse --option=flag syntax
                    let parts = arg.split(separator: "=", maxSplits: 2, omittingEmptySubsequences: false)
                    supplied = String(parts[1])
                } else {
                    // check if the next arg is available
                    if i + 1 < arguments.count {
                        let next = arguments[i + 1]
                        // ensure it's non-nil and not an option
                        if next?.hasPrefix("-") == false {
                            supplied = next
                            arguments[i + 1] = nil
                        } else {
                            supplied = nil
                        }
                    } else {
                        supplied = nil
                    }
                }


                // value options need either a supplied value or a default
                guard let value = supplied ?? d else {
                    throw CommandError(
                        identifier: "optionValueRequired",
                        reason: "A value is required for option `\(option.name)`"
                    )
                }

                return value
            }
        }

        return nil
    }

    /// Parses the argument from input, returning `nil` if it could not be found.
    ///
    ///     var input = CommandInput(arguments: ["exec", "--foo", "bar", "baz"])
    ///     print(input.arguments) // ["--foo", "bar", "baz"]
    ///     let message = try input.parse(argument: .argument(name: "message")
    ///     print(message) // Optional("baz")
    ///     print(input.arguments) // ["--foo", "bar"]
    ///
    /// - parameters:
    ///     - argument: The `CommandArgument` to parse from this `CommandInput`.
    public mutating func parse(argument: AnyArgument) throws -> String? {
        // create a temporary [String?] array so it's
        // easier to mark positions as "consumed"
        var arguments = self.arguments.map { $0 as String? }
        defer { self.arguments = arguments.compactMap { $0 } }

        for (i, arg) in arguments.enumerated() {
            guard let arg = arg else { continue }

            guard !arg.hasPrefix("-") else {
                // all options should have been parsed first
                return nil
            }

            arguments[i] = nil
            return arg
        }

        return nil
    }
}
