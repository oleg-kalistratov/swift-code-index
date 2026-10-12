import MCP
@preconcurrency import IndexStoreDB
import Foundation

func handleFindImplementations(_ args: [String: Value], indexStore: IndexStore) async throws -> CallTool.Result {
    guard let database = await indexStore.database else {
        return .failure("No index loaded. Call loadIndex first.")
    }

    guard let usr = args["usr"]?.stringValue else {
        return .failure("Missing required argument: usr")
    }

    let includeSystem = args["includeSystem"]?.boolValue ?? false
    let includeStale = args["includeStale"]?.boolValue ?? false

    // A type's `: P` clause is an occurrence of P whose baseOf relation names the
    // conforming or inheriting type (or the extension that adds the conformance).
    let conformances = database.occurrences(ofUSR: usr, roles: .baseOf)
    // A member that satisfies a protocol requirement or overrides a method is a
    // definition carrying an overrideOf relation to that requirement or method.
    let overrides = database.occurrences(relatedToUSR: usr, roles: .overrideOf)

    let all = (conformances + overrides).uniqued()
    let nonSystem = all.filter { includeSystem || !$0.location.isSystem }
    let results = nonSystem
        .filter { includeStale || !$0.isStale(in: database) }
        .sorted { ($0.location.path, $0.location.line) < ($1.location.path, $1.location.line) }

    if results.isEmpty && all.isEmpty {
        return .success("No implementations found. Pass the USR of a protocol, class, protocol requirement, or overridable method (from searchSymbol). Types in test targets appear only after the tests were built.")
    }

    let items: [[String: String]] = results.map { $0.toImplementationDict(of: usr) }
    let output = try formatOccurrenceJSON(items, systemCount: all.count - nonSystem.count, staleCount: nonSystem.count - results.count)
    return .success(output)
}

extension SymbolOccurrence {
    /// Compact dict naming the implementing symbol rather than the occurrence's own.
    /// For a conformance the occurrence is the protocol or superclass reference, so
    /// the implementer is the symbol on the other end of its baseOf relation; for an
    /// override the occurrence is the implementing member itself.
    /// Keys: usr, name, kind, location ("path:line"), subKind (when present).
    func toImplementationDict(of usr: String) -> [String: String] {
        let implementer = relations.first { $0.roles.contains(.baseOf) && symbol.usr == usr }?.symbol ?? symbol
        var dict: [String: String] = [
            "usr":      implementer.usr,
            "name":     implementer.name,
            "kind":     String(describing: implementer.kind),
            "location": "\(location.path):\(location.line)",
        ]
        if implementer.subKind != .none {
            dict["subKind"] = String(describing: implementer.subKind)
        }
        return dict
    }
}
