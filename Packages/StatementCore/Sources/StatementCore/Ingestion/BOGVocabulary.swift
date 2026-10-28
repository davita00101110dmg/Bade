/// BOG exports the same layout in either language; only the field labels change.
struct BOGVocabulary: Sendable {
    /// Which set of patterns to read the rate-bearing rows with. The labels below are matched as
    /// plain text, but a rate row is a regex, and a regex literal cannot be built from a string —
    /// so the language is carried here and the literals are chosen from it.
    enum Language: Sendable { case english, georgian }

    let language: Language
    let recordStart: String
    let merchant: String
    let date: String
    /// Which side of a card conversion is the bank's own rate; the other side is the scheme's.
    let bankRate: String

    static let english = BOGVocabulary(
        language: .english, recordStart: "Payment - Amount", merchant: "Merchant:", date: "Date:",
        bankRate: "Bank")
    static let georgian = BOGVocabulary(
        language: .georgian, recordStart: "გადახდა - თანხა", merchant: "ობიექტი:",
        date: "თარიღი:", bankRate: "ბანკის")

    static let all: [BOGVocabulary] = [.english, .georgian]
}
