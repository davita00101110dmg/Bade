import Foundation
import Testing

@testable import Localization

/// Validates the catalog source. SwiftPM does not run xcstringstool, so compiled .lproj folders
/// exist only in Xcode builds; checking the JSON works in both and catches what actually breaks.
@Suite("String catalog")
struct StringCatalogTests {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable {
                    let state: String
                    let value: String
                }
                let stringUnit: Unit
            }
            let localizations: [String: Localization]
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private static let catalog: Catalog = {
        let url = Bundle.bade.url(forResource: "Localizable", withExtension: "xcstrings")!
        return try! JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }()

    /// Views reference typed constants, so raw keys exist only in `Strings.swift`. Scraping it
    /// catches a typo there, which would otherwise surface as a key rendered on screen.
    private static let usedKeys: Set<String> = {
        let file = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/Localization/Strings.swift")
        let source = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
        let pattern = /string\("([a-z][a-zA-Z]*(?:\.[a-zA-Z0-9]+)+)/
        return Set(source.matches(of: pattern).map { String($0.1) })
    }()

    /// Interpolated keys carry their format specifiers, so compare up to the first placeholder.
    private static func stem(_ key: String) -> String {
        String(key.prefix { $0 != " " })
    }

    @Test func everyCatalogKeyIsReachableFromCode() {
        for key in Self.catalog.strings.keys.sorted() {
            #expect(
                Self.usedKeys.contains(Self.stem(key)),
                "\(key) is in the catalog but no constant exposes it")
        }
    }

    @Test func englishIsTheSourceLanguage() {
        #expect(Self.catalog.sourceLanguage == "en")
    }

    @Test func everyKeyUsedInAFeatureExistsInTheCatalog() {
        #expect(!Self.usedKeys.isEmpty, "key scraping found nothing — the scan is broken")
        for key in Self.usedKeys.sorted() {
            #expect(
                Self.catalog.strings.keys.contains { Self.stem($0) == key },
                "\(key) has a constant but is not in the catalog")
        }
    }

    @Test func everyKeyHasEnglishAndGeorgian() {
        for (key, entry) in Self.catalog.strings {
            #expect(entry.localizations["en"] != nil, "\(key) has no English")
            #expect(entry.localizations["ka"] != nil, "\(key) has no Georgian")
        }
    }

    /// A translation that loses a placeholder formats the wrong argument into the wrong slot, and
    /// the only way to see it is to run the app in that language and reach that screen. Georgian
    /// gets edited far more than English does, so the parity is worth pinning here.
    @Test func everyTranslationCarriesTheSamePlaceholders() {
        let placeholder = /%(?:\d+\$)?(?:#@[A-Za-z]+@|lld|lf|@)/
        for (key, entry) in Self.catalog.strings {
            guard let english = entry.localizations["en"], let georgian = entry.localizations["ka"]
            else { continue }
            let expected = english.stringUnit.value.matches(of: placeholder).map { String($0.0) }
            let actual = georgian.stringUnit.value.matches(of: placeholder).map { String($0.0) }

            #expect(
                expected.sorted() == actual.sorted(),
                "\(key) has \(expected) in English but \(actual) in Georgian")
        }
    }

    @Test func noEntryIsBlank() {
        for (key, entry) in Self.catalog.strings {
            for (language, localization) in entry.localizations {
                #expect(
                    !localization.stringUnit.value.trimmingCharacters(in: .whitespaces).isEmpty,
                    "\(key) is blank in \(language)")
            }
        }
    }
}
