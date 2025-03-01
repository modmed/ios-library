// Copyright Airship and Contributors

import Foundation

/// Matcher for a JSON payload.
public final class JSONMatcher: NSObject, Sendable {

    private static let keyKey = "key"
    private static let scopeKey = "scope"
    private static let valueKey = "value"
    private static let ignoreCaseKey = "ignore_case"
    private static let errorDomainKey = "com.urbanairship.json_matcher"

    private let key: String?
    private let scope: [String]?
    private let valueMatcher: JSONValueMatcher
    private let ignoreCase: Bool?

    private
        init(
            valueMatcher: JSONValueMatcher,
            key: String?,
            scope: [String]?,
            ignoreCase: Bool?
        )
    {
        self.valueMatcher = valueMatcher
        self.key = key
        self.scope = scope
        self.ignoreCase = ignoreCase
        super.init()
    }

    /**
     * Factory method to create a JSON matcher.
     *
     * - Parameters:
     *   -  valueMatcher Matcher to apply to the value.
     * - Returns: A JSONMatcher instance.
     */
    public convenience init(valueMatcher: JSONValueMatcher) {
        self.init(
            valueMatcher: valueMatcher,
            key: nil,
            scope: nil,
            ignoreCase: nil
        )
    }

    /**
     * Factory method to create a JSON matcher.
     *
     * - Parameters:
     *   - valueMatcher Matcher to apply to the value.
     *   - scope Used to path into the object before evaluating the value.
     * - Returns: A JSONMatcher instance.
     */
    public convenience init(valueMatcher: JSONValueMatcher, scope: [String]) {
        self.init(
            valueMatcher: valueMatcher,
            key: nil,
            scope: scope,
            ignoreCase: nil
        )
    }

    /// - Note: For internal use only. :nodoc:
    public convenience init(valueMatcher: JSONValueMatcher, ignoreCase: Bool) {
        self.init(
            valueMatcher: valueMatcher,
            key: nil,
            scope: nil,
            ignoreCase: ignoreCase
        )
    }

    /// - Note: For internal use only. :nodoc:
    public convenience init(valueMatcher: JSONValueMatcher, key: String) {
        self.init(
            valueMatcher: valueMatcher,
            key: key,
            scope: nil,
            ignoreCase: nil
        )
    }

    /// - Note: For internal use only. :nodoc:
    public convenience init(
        valueMatcher: JSONValueMatcher,
        key: String,
        scope: [String]
    ) {
        self.init(
            valueMatcher: valueMatcher,
            key: key,
            scope: scope,
            ignoreCase: nil
        )
    }

    /// - Note: For internal use only. :nodoc:
    public convenience init(
        valueMatcher: JSONValueMatcher,
        scope: [String],
        ignoreCase: Bool
    ) {
        self.init(
            valueMatcher: valueMatcher,
            key: nil,
            scope: scope,
            ignoreCase: ignoreCase
        )
    }

    /**
     * Factory method to create a matcher from a JSON payload.
     *
     * - Parameters:
     *   - json The JSON payload.
     *   - error An NSError pointer for storing errors, if applicable.
     * - Returns: A JSONMatcher instance or `nil` if the JSON is invalid.
     */
    public convenience init(json: Any?) throws {
        guard let info = json as? [String: Any] else {
            throw AirshipErrors.error(
                "Attempted to deserialize invalid object: \(json ?? "")"
            )
        }

        /// Optional scope
        var scope: [String]?
        if let scopeJSON = info[JSONMatcher.scopeKey] {
            if let value = scopeJSON as? String {
                scope = [value]
            } else if let value = scopeJSON as? [String] {
                scope = value
            } else {
                throw AirshipErrors.error(
                    "Scope must be either an array of strings or a string. Invalid value: \(scopeJSON)"
                )
            }
        }

        /// Optional key
        var key: String?
        if let keyJSON = info[JSONMatcher.keyKey] {
            guard let value = keyJSON as? String else {
                throw AirshipErrors.error(
                    "Key must be a string. Invalid value: \(keyJSON)"
                )
            }
            key = value
        }

        /// Optional case insensitivity
        var ignoreCase: Bool?
        if let ignoreCaseJSON = info[JSONMatcher.ignoreCaseKey] {
            guard let value = ignoreCaseJSON as? Bool else {
                throw AirshipErrors.error(
                    "Ignore case must be a bool. Invalid value: \(ignoreCaseJSON)"
                )
            }
            ignoreCase = value
        }

        /// Required value
        let valueMatcher = try JSONValueMatcher.matcherWithJSON(
            info[JSONMatcher.valueKey]
        )
        self.init(
            valueMatcher: valueMatcher,
            key: key,
            scope: scope,
            ignoreCase: ignoreCase
        )
    }

    /**
     * The matcher's JSON payload.
     */
    public func payload() -> [String: Any] {
        var payload: [String: Any] = [:]
        payload[JSONMatcher.valueKey] = valueMatcher.payload()
        payload[JSONMatcher.keyKey] = key
        payload[JSONMatcher.scopeKey] = scope
        payload[JSONMatcher.ignoreCaseKey] = ignoreCase
        return payload
    }

    /**
     * Evaluates the object with the matcher.
     *
     * - Parameters:
     *   - value: The object to evaluate.
     * - Returns: true if the matcher matches the object, otherwise false.
     */
    public func evaluate(_ value: Any?) -> Bool {
        return evaluate(value, ignoreCase: self.ignoreCase ?? false)
    }

    /// - Note: For internal use only. :nodoc:
    public func evaluate(_ value: Any?, ignoreCase: Bool) -> Bool {
        var object = value

        var paths: [String] = []
        if let scope = scope {
            paths.append(contentsOf: scope)
        }

        if let key = key {
            paths.append(key)
        }

        for path in paths {
            guard let obj = object as? [String: Any]? else {
                object = nil
                break
            }
            object = obj?[path]
        }

        return valueMatcher.evaluate(object, ignoreCase: ignoreCase)
    }

    /// - Note: For internal use only. :nodoc:
    public override func isEqual(_ other: Any?) -> Bool {
        guard let matcher = other as? JSONMatcher else {
            return false
        }

        if self === matcher {
            return true
        }

        return isEqual(to: matcher)
    }

    /// - Note: For internal use only. :nodoc:
    public func isEqual(to matcher: JSONMatcher) -> Bool {
        guard self.valueMatcher == matcher.valueMatcher,
            self.key == matcher.key,
            self.scope == matcher.scope,
            self.ignoreCase ?? false == matcher.ignoreCase ?? false
        else {
            return false
        }

        return true
    }

    func hash() -> Int {
        var result = 1
        result = 31 * result + valueMatcher.hashValue
        result = 31 * result + (key?.hashValue ?? 0)
        result = 31 * result + (scope?.hashValue ?? 0)
        result = 31 * result + (ignoreCase?.hashValue ?? 0)
        return result
    }
}
