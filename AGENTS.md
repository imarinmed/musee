# Musee Swift Code Quality Rules

## 1. General Principles
- **Clarity over Cleverness**: Code must be readable by a junior developer. Avoid complex one-liners.
- **Consistency**: Follow Apple's Swift API Design Guidelines and common conventions.
- **Performance**: Optimize for readability first, then performance. Use instruments for bottlenecks.
- **Safety**: Use `Result`, `Optional`, and error handling. Avoid force-unwrapping except in tests.
- **Modularity**: Keep modules small, focused, and testable. Use protocols for abstraction.
- **Documentation**: Every public API must have SwiftDocC comments. Use `///` for brief, `/** */` for detailed.
- **Elegance**: Code should be expressive, beautiful, and delightful to read. Prioritize clarity and intent.
- **Functional Programming**: Embrace immutability, pure functions, and functional composition where appropriate.

## 2. Naming Conventions
- **Types**: PascalCase (e.g., `Person`, `MediaAsset`).
- **Functions/Methods**: camelCase, descriptive (e.g., `savePerson(_:)`).
- **Variables**: camelCase, descriptive (e.g., `personName` not `p`).
- **Constants**: camelCase with descriptive names (e.g., `maxRetries`).
- **Enums**: PascalCase for cases if they are types (e.g., `case image`, `case video`).
- **Avoid Abbreviations**: Use `identifier` not `id`, `count` not `cnt`.

## 3. Code Structure
- **File Organization**: One type per file, unless closely related. Group by feature/module.
- **Function Length**: < 50 lines. Break into smaller functions.
- **Class/Struct Size**: < 200 lines. Split responsibilities.
- **Imports**: Alphabetize, group by system/external, avoid unused.
- **Access Control**: `private` by default, `public` only when necessary.

## 4. Error Handling
- **Throw Errors**: Use `throws` for recoverable errors. Define custom `Error` enums.
- **Result Types**: For async operations, prefer `Result<T, Error>`.
- **Logging**: Use `os.log` for debugging, not print. Level: debug, info, error.
- **Never Force Unwrap**: Use `if let` or `guard let` instead of `!`. Force unwrap only in tests.
- **Custom Error Types**: Define specific error enums for each domain, conforming to `Error`.
- **Error Propagation**: Use `try?` for optional results, `try!` only when guaranteed success.

## 5. Concurrency
- **Async/Await**: Prefer over DispatchQueue. Use `Task` for unstructured concurrency.
- **Actors**: Use for shared mutable state.
- **Sendable**: Mark types as `Sendable` when crossing concurrency boundaries.
- **Task Cancellation**: Always check for cancellation in long-running tasks.
- **MainActor**: Use `@MainActor` for UI-related code and state updates.

## 6. Functional Programming
- **Immutability**: Prefer `let` over `var`. Use value types (structs) when possible.
- **Pure Functions**: Functions should be deterministic and have no side effects.
- **Composition**: Use function composition with `map`, `filter`, `reduce`, and `compactMap`.
- **Optionals**: Embrace optional chaining and `if let`/`guard let` patterns.
- **Result Types**: Use `Result<T, Error>` for operations that can fail.
- **Higher-Order Functions**: Leverage closures and function parameters for flexibility.

## 7. Testing
- **Coverage**: Aim for 90%+ line coverage.
- **Unit Tests**: Test logic, not implementation details.
- **Integration Tests**: Test module interactions.
- **Mocks**: Use protocols for testability.

## 8. Dependencies
- **Minimal External Deps**: Prefer Foundation, Swift standard library. Only add if necessary.
- **Version Pinning**: Use exact versions in Package.swift.
- **Abstraction**: Wrap external deps behind protocols.

## 9. Style
- **Indentation**: 4 spaces.
- **Line Length**: 120 characters max.
- **Braces**: Same line for functions, new line for types.
- **Whitespace**: Spaces around operators, no trailing whitespace.
- **Comments**: Explain why, not what. Use TODO/FIXME for placeholders.

## 10. Performance
- **Lazy Evaluation**: Use `lazy` where appropriate.
- **Value Types**: Prefer structs over classes unless reference semantics needed.
- **Memory Management**: Avoid retain cycles. Use weak/unowned.

## 11. Security
- **Input Validation**: Validate all inputs.
- **Encryption**: Use CryptoKit for crypto operations.
- **Privacy**: Handle sensitive data carefully, use Keychain for secrets.

## 12. SwiftUI (if applicable)
- **State Management**: Use `@State`, `@ObservedObject`, etc. appropriately.
- **Views**: Keep small, composable. Use `ViewModifier` for reusable logic.

## 13. Code Elegance Standards

### Always Elegant Code
- **Expressive Naming**: Choose names that clearly express intent and behavior
- **Readable Flow**: Structure code for logical flow, minimize cognitive load
- **Beautiful Patterns**: Use Swift's expressive features to create beautiful, maintainable code
- **Self-Documenting**: Write code that tells its own story through structure and naming

### Documentation Excellence
- **Comprehensive API Docs**: Every public API needs detailed SwiftDocC documentation
- **Parameter Documentation**: Document all parameters, return values, and thrown errors
- **Usage Examples**: Include code examples in documentation where helpful
- **Design Rationale**: Explain why design decisions were made, not just what they are

## 14. Enforcement
- **Linting**: swiftlint with rules matching above.
- **Formatting**: swift-format with 4-space indent, 120 line length.
- **CI/CD**: Run lint/format/test on every PR.
- **Build Verification**: Must run `swift build` and ensure zero compilation errors and zero warnings before considering any task complete.
- **Task Completion**: Always consider tasks unfinished until the code builds without errors or warnings.

These rules will be enforced in all Musee code. Our commitment to code elegance ensures that every line of code is expressive, safe, and maintainable. We strive for beautiful, functional Swift that delights both developers and users.