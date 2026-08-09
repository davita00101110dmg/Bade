/// BOG exports the same layout in either language; only the field labels change.
struct BOGVocabulary: Sendable {
    let recordStart: String
    let merchant: String
    let date: String

    static let english = BOGVocabulary(
        recordStart: "Payment - Amount", merchant: "Merchant:", date: "Date:")
    static let georgian = BOGVocabulary(
        recordStart: "გადახდა - თანხა", merchant: "ობიექტი:", date: "თარიღი:")

    static let all: [BOGVocabulary] = [.english, .georgian]
}
