#!/usr/bin/env xcrun --sdk macosx swift
//
//  Main.swift
//  CheckLocalizedStrings
//
//  Created by Mikael (https://github.com/mikaelbo) on 2018-04-02.
//  Copyright © 2018 Mikael. All rights reserved.
//

import Foundation

// MARK: - Extensions

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

extension String {
    func matches(for regex: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            return regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Structs

struct LocalizedValue {
    let value: String
    let path: String
    let lineNumber: Int
}

struct LocalizedString {
    let key: String
    let value: String
    let lineNumber: Int
}

// MARK: - Start

guard let scriptPath = CommandLine.arguments.first, let projectPath = CommandLine.arguments[safe: 1] else {
    print("PROJECT DIR argument not found")
    exit(0)
}

let functionCall = CommandLine.arguments[safe: 2] ?? "NSLocalizedString"

var variables = [String]()
if let vars = CommandLine.arguments[safe: 3] {
    variables = vars.components(separatedBy: ",").filter{ !$0.isEmpty }
}

var ignoreFiles = ["main.swift"]
if let files = CommandLine.arguments[safe: 4] {
    ignoreFiles.append(contentsOf: files.components(separatedBy: ",").filter{ !$0.isEmpty })
}

let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let url = URL(fileURLWithPath: scriptPath, relativeTo: currentDirectoryURL)
let scriptRelativePath = url.path.replacingOccurrences(of: currentDirectoryURL.path + "/", with: "")
let projectFolderPath = (projectPath as NSString).lastPathComponent
let excludedDirectories = ["Pods", "Frameworks", "Products"]

var allPaths: [String] = {
    var strings = [String]()
    if let enumerator = FileManager.default.enumerator(atPath: projectPath) {
        for case let string as String in enumerator {
            for directory in excludedDirectories {
                let subdirectoryString = projectFolderPath + "/" + directory
                if string.hasPrefix(directory + "/") ||
                    string.hasPrefix(subdirectoryString + "/") ||
                    string == directory ||
                    string == subdirectoryString {
                    continue
                }
            }
            strings.append(projectPath + "/" + string)
        }
    }
    return strings
}()

func main() {
    let keysAndLanguages = findExistingLocalizedKeysAndLanguages()
    let existingKeys = keysAndLanguages.keys
    let languages = keysAndLanguages.languages
    let usedKeys = findUsedLocalizedStringKeys()
    let missingKeys = findMissingKeys(existingKeys: existingKeys, usedKeys: usedKeys, languages: languages)
    let unusedKeys = findUnusedKeys(existingKeys: existingKeys, usedKeys: usedKeys)
    let mismatchedParameters = findMismatchedParameters(existingKeys: existingKeys)
    printUnusedKeys(unusedKeys)
    printMissingKeys(missingKeys)
    printMismatchedParameters(mismatchedParameters)
}

// MARK: - Existing keys & Languages

func findExistingLocalizedKeysAndLanguages() -> (keys: [String: [LocalizedValue]], languages: Set<String>) {
    let strings = allPaths.filter { return $0.hasSuffix("Localizable.strings") }
    var keys = [String: [LocalizedValue]]()
    var languages = Set<String>()
    var fileCount = 0

    for file in strings {
        fileCount += 1
        for localizedString in localizedStringKeyValues(inFile: file) {
            let value = LocalizedValue(value: localizedString.value,
                                       path: file,
                                       lineNumber: localizedString.lineNumber)
            if var values = keys[localizedString.key] {
                let containsPath = values.compactMap { return $0.path }.contains(value.path)
                if containsPath {
                    let message = "Redefined key \(localizedString.key) in file: \(language(forPath: file) ?? "")"
                    logError(message, path: file, line: localizedString.lineNumber)
                    exit(1)
                } else {
                    values.append(value)
                    keys[localizedString.key] = values
                }
            } else {
                keys[localizedString.key] = [value]
            }
        }
        if let language = language(forPath: file) {
            languages.insert(language)
        }
    }
    print("Found \(keys.count) defined string keys in \(fileCount) files")
    return (keys, languages)
}

func localizedStringKeyValues(inFile path: String) -> [LocalizedString] {
    var localizedKeys = [LocalizedString]()
    for (index, line) in lines(inFile: path, encoding: .utf8).enumerated() {
        if !line.hasPrefix("//"),
           let localizedKey = localizedStringKeyValue(atLine: line, lineNumber: index + 1) {
            localizedKeys.append(localizedKey)
        }
    }
    return localizedKeys
}

func localizedStringKeyValue(atLine line: String, lineNumber: Int) -> LocalizedString? {
    let results = line.matches(for: "^\\s*\"(.+)\"\\s*=\\s*\"(.*)\"\\s*;")
    if let result = results.first,
       result.numberOfRanges > 2,
       let first = Range(result.range(at: 1), in: line),
       let second = Range(result.range(at: 2), in: line) {
        return LocalizedString(key: String(line[first]),
                               value: String(line[second]),
                               lineNumber: lineNumber)
    }
    return nil
}

// MARK: - Used keys

func findUsedLocalizedStringKeys() -> [String: [LocalizedValue]] {
    let files = allPaths.filter {
        for file in ignoreFiles {
            if $0.hasSuffix(file) {
                return false
            }
        }
        return ($0.hasSuffix(".m") || $0.hasSuffix(".swift") || pathIsStoryboardOrXib($0))
    }
    var keys = [String: [LocalizedValue]]()
    for file in files {
        for key in localizedStringKeys(inFile: file) {
            if var values = keys[key.value] {
                values.append(key)
                keys[key.value] = values
            } else {
                keys[key.value] = [key]
            }
        }
    }
    return keys
}

func localizedStringKeys(inFile path: String) -> [LocalizedValue] {
    var localizedStringsArray = [LocalizedValue]()
    for (index, line) in lines(inFile: path).enumerated() {
        if !line.hasPrefix("//") {
            let stringKeys = localizedStringKeys(atLine: line, inPath: path, lineNumber: index + 1)
            localizedStringsArray.append(contentsOf: stringKeys)
        }
    }
    return localizedStringsArray
}

func localizedStringKeys(atLine line: String, inPath path: String, lineNumber: Int) -> [LocalizedValue] {
    if pathIsStoryboardOrXib(path) {
        var matches = [NSTextCheckingResult]()
        for variable in variables {
            matches.append(contentsOf: line.matches(for: "keyPath=\"\(variable)\" value=\"(.*?)\""))
        }
        return matches.compactMap {
            if let range = Range($0.range(at: 1), in: line) {
                return LocalizedValue(value: String(line[range]), path: path, lineNumber: lineNumber)
            }
            return nil
        }
    } else {
        var matches = [NSTextCheckingResult]()
        matches.append(contentsOf: line.matches(for: "\(functionCall)\\(*?@?\"(.*?)\"[,)]"))

        for variable in variables {
            matches.append(contentsOf: line.matches(for: "\(variable) = \"(.*?)\""))
        }

        return matches.compactMap {
            if let range = Range($0.range(at: 1), in: line) {
                return LocalizedValue(value: String(line[range]), path: path, lineNumber: lineNumber)
            }
            return nil
        }
    }
}

// MARK: - Missing keys

func findMissingKeys(existingKeys: [String: [LocalizedValue]],
                     usedKeys: [String: [LocalizedValue]],
                     languages projectLanguages: Set<String>) -> [String: Set<String>] {
    var missingKeys = [String: Set<String>]()
    for key in existingKeys.keys {
        let keyLanguages = languages(forKey: key, inKeys: existingKeys)
        let missingLanguages = Set(projectLanguages.compactMap {
            return keyLanguages.contains($0) ? nil : $0
        })
        if !missingLanguages.isEmpty {
            missingKeys[key] = missingLanguages
        }
    }
    for key in usedKeys.keys {
        let keyLanguages = languages(forKey: key, inKeys: existingKeys)
        let missingLanguages = Set(projectLanguages.compactMap {
            return keyLanguages.contains($0) ? nil : $0
        })
        if !missingLanguages.isEmpty {
            missingKeys[key] = missingLanguages
        }
    }
    return missingKeys
}

func languages(forKey key: String, inKeys keys: [String: [LocalizedValue]]) -> Set<String> {
    var languages = Set<String>()
    if let values = keys[key] {
        for value in values {
            if let language = language(forPath: value.path) {
                languages.insert(language)
            }
        }
    }
    return languages
}

// MARK: - Unused keys

func findUnusedKeys(existingKeys: [String: [LocalizedValue]],
                    usedKeys: [String: [LocalizedValue]]) -> [String: [LocalizedValue]] {
    var unusedKeys = [String: [LocalizedValue]]()
    for (key, value) in existingKeys {
        if usedKeys[key] == nil {
            unusedKeys[key] = value
        }
    }
    return unusedKeys
}

// MARK: - Mismatched parameters

func findMismatchedParameters(existingKeys: [String : [LocalizedValue]]) -> [String: [LocalizedValue]] {
    var mismatchedKeys = [String: [LocalizedValue]]()
    for (key, values) in existingKeys {
        if !parametersAreMatching(inValues: values) {
            mismatchedKeys[key] = values
        }
    }
    return mismatchedKeys
}

func parametersAreMatching(inValues values: [LocalizedValue]) -> Bool {
    let keys = "%(?:\\d+\\$)?[+-]?(?:[lh]{0,2})(?:[qLztj])?(?:[ 0]|'.{1})?\\d*(?:\\.\\d+)?[@dDiuUxXoOfeEgGcCsSpaAFn]"
    var previousParams: [String]?
    for value in values {
        let string = value.value
        let params: [String] = string.matches(for: keys).compactMap {
            if let range = Range($0.range, in: string) {
                return String(string[range])
            }
            return nil
        }

        if let previous = previousParams {
            if params.count != previous.count {
                return false
            }
            for (index, param) in params.enumerated() {
                guard let otherParam = previous[safe: index], param == otherParam else {
                    return false
                }
            }
        }
        previousParams = params
    }
    return true
}

// MARK: - Convenience

func lines(inFile path: String, encoding: String.Encoding = .utf8) -> [String] {
    do {
        let string = try String(contentsOfFile: path, encoding: encoding)
        return string.components(separatedBy: .newlines)
    } catch {
        print(error)
    }
    return [String]()
}

func language(forPath path: String) -> String? {
    if let result = path.matches(for: "([^\\/]*)\\.lproj").first,
       let range = Range(result.range(at: 1), in: path) {
        return String(path[range])
    }
    return nil
}

func pathIsStoryboardOrXib(_ path: String) -> Bool {
    return path.hasSuffix(".storyboard") || path.hasSuffix(".xib")
}

func path(forLanguage language: String) -> String? {
    return allPaths.filter { return $0.hasSuffix("\(language).lproj/Localizable.strings") }.first
}

// MARK: Printing

func printUnusedKeys(_ keys: [String: [LocalizedValue]], printIndividually: Bool = false) {
    if keys.isEmpty {
        return
    }

    print("\n--------- Unused strings ---------\n")
    for (key, values) in keys {
        if !printIndividually && values.count > 1 {
            let languages = values.compactMap { return language(forPath: $0.path) }.sorted().joined(separator: ", ")
            logWarning("Unused localized string \(key) for languages (\(languages))")
        } else {
            for value in values {
                let message = "Unused localized string \(key) in \(language(forPath: value.path) ?? "")"
                logWarning(message, path: value.path, line: value.lineNumber)
            }
        }
    }
}

func printMissingKeys(_ keys: [String: Set<String>], printIndividually: Bool = false) {
    if keys.isEmpty {
        return
    }

    print("\n--------- Missing strings ---------\n")
    for (key, values) in keys {
        if !printIndividually && values.count > 1 {
            let languages = values.sorted().joined(separator: ", ")
            logWarning("Missing localized string \(key) for languages (\(languages))")
        } else {
            for value in values {
                let message = "Missing localized string \(key) in \(value)"
                logWarning(message, path: path(forLanguage: value) ?? "")
            }
        }
    }
}

func printMismatchedParameters(_ keys: [String : [LocalizedValue]]) {
    if keys.isEmpty {
        return
    }

    print("\n--------- Missmatched parameters ---------\n")
    for key in keys.keys.sorted() {
        logWarning("Parameter mismatch between languages for key \(key)")
    }
}

func logWarning(_ message: String, path: String = "", line: Int? = nil) {
    log("warning: \(message)", path: path, line: line)
}

func logError(_ message: String, path: String = "", line: Int? = nil) {
    log("error: \(message)", path: path, line: line)
}

func log(_ message: String, path: String = "", line: Int? = nil) {
    var lineString = ""
    if let line = line {
        lineString = String(line)
    }
    print("\(path):\(lineString): \(message)")
}


main()

