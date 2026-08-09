import Core

/// Seed of internationally-available subscription services. Prices are published list prices in
/// their billing currency and drift over time; a stale price simply fails to match, which costs a
/// confidence promotion and never produces a wrong one. Georgian services are deliberately absent
/// until real local pricing is available — see CLAUDE.md.
public enum MerchantSeed {
    public static let entries: [CatalogEntry] = video + music + storage + productivity + developer
        + ai + gaming + fitness + education + news + social + commerce

    static let video: [CatalogEntry] = [
        .init("Netflix", .monthly, pricePoints: [.monthly("7.99"), .monthly("17.99"), .monthly("24.99")]),
        .init("Disney Plus", .monthly, aliases: ["disneyplus", "disney+"], pricePoints: [.monthly("9.99"), .monthly("15.99"), .annual("159.99")]),
        .init("HBO Max", .monthly, aliases: ["hbomax", "max.com"], pricePoints: [.monthly("9.99"), .monthly("16.99"), .annual("169.99")]),
        .init("Hulu", .monthly, pricePoints: [.monthly("9.99"), .monthly("18.99")]),
        .init("Apple TV Plus", .monthly, aliases: ["appletv"], pricePoints: [.monthly("12.99")]),
        .init("Paramount Plus", .monthly, aliases: ["paramountplus"], pricePoints: [.monthly("7.99"), .monthly("12.99")]),
        .init("Peacock", .monthly, pricePoints: [.monthly("7.99"), .monthly("13.99")]),
        .init("YouTube Premium", .monthly, aliases: ["youtubepremium", "googleyoutube"], pricePoints: [.monthly("13.99"), .monthly("22.99")]),
        .init("Crunchyroll", .monthly, pricePoints: [.monthly("7.99"), .monthly("11.99")]),
        .init("MUBI", .monthly),
        .init("Shudder", .monthly),
        .init("BritBox", .monthly),
        .init("Curiosity Stream", .annual, aliases: ["curiositystream"]),
        .init("DAZN", .monthly),
        .init("Viaplay", .monthly),
        .init("Amazon Prime Video", .monthly, aliases: ["primevideo"]),
    ]

    static let music: [CatalogEntry] = [
        .init("Spotify", .monthly, pricePoints: [.monthly("11.99"), .monthly("16.99"), .monthly("19.99")]),
        .init("Apple Music", .monthly, aliases: ["applemusic"], pricePoints: [.monthly("10.99"), .monthly("16.99")]),
        .init("YouTube Music", .monthly, aliases: ["youtubemusic"], pricePoints: [.monthly("10.99")]),
        .init("Tidal", .monthly, pricePoints: [.monthly("10.99")]),
        .init("Deezer", .monthly, pricePoints: [.monthly("11.99")]),
        .init("SoundCloud", .monthly),
        .init("Audible", .monthly, pricePoints: [.monthly("14.95")]),
        .init("Amazon Music", .monthly, aliases: ["amazonmusic"]),
        .init("Pandora", .monthly),
    ]

    static let storage: [CatalogEntry] = [
        .init("Apple", .monthly, aliases: ["applecombill", "applecom", "applebill"]),
        .init("iCloud", .monthly, aliases: ["appleicloud", "icloudplus"], pricePoints: [.monthly("0.99"), .monthly("2.99"), .monthly("9.99")]),
        .init("Google One", .monthly, aliases: ["googleone", "googlestorage"], pricePoints: [.monthly("1.99"), .monthly("2.99"), .monthly("9.99"), .annual("19.99")]),
        .init("Dropbox", .monthly, pricePoints: [.monthly("11.99"), .annual("119.88")]),
        .init("OneDrive", .monthly, aliases: ["microsoftonedrive"]),
        .init("Box", .monthly),
        .init("pCloud", .annual),
        .init("Backblaze", .monthly, pricePoints: [.monthly("9.00")]),
        .init("Mega", .monthly),
    ]

    static let productivity: [CatalogEntry] = [
        .init("Microsoft 365", .annual, aliases: ["microsoft365", "office365"], pricePoints: [.monthly("9.99"), .annual("99.99"), .annual("69.99")]),
        .init("Google Workspace", .monthly, aliases: ["googleworkspace", "gsuite"]),
        .init("Notion", .monthly, pricePoints: [.monthly("10.00")]),
        .init("Evernote", .monthly),
        .init("Todoist", .annual, pricePoints: [.annual("36.00")]),
        .init("Superhuman", .monthly, pricePoints: [.monthly("30.00")]),
        .init("Slack", .monthly),
        .init("Zoom", .monthly, pricePoints: [.monthly("15.99"), .annual("149.90")]),
        .init("Trello", .monthly),
        .init("Asana", .monthly),
        .init("Monday", .monthly, aliases: ["mondaycom"]),
        .init("ClickUp", .monthly),
        .init("Miro", .monthly),
        .init("Figma", .monthly, pricePoints: [.monthly("12.00"), .monthly("15.00")]),
        .init("Canva", .annual, aliases: ["canvaptylim"], pricePoints: [.monthly("14.99"), .annual("119.99")]),
        .init("Grammarly", .monthly, pricePoints: [.monthly("12.00"), .monthly("30.00")]),
        .init("1Password", .annual, aliases: ["onepassword", "agilebits"], pricePoints: [.monthly("2.99"), .annual("35.88")]),
        .init("LastPass", .annual),
        .init("Dashlane", .annual),
        .init("Bitwarden", .annual, pricePoints: [.annual("10.00")]),
        .init("NordVPN", .annual),
        .init("ExpressVPN", .annual),
        .init("Surfshark", .annual),
        .init("Proton", .annual, aliases: ["protonmail", "protonvpn"]),
    ]

    static let developer: [CatalogEntry] = [
        .init("GitHub", .monthly, pricePoints: [.monthly("4.00"), .monthly("21.00")]),
        .init("GitLab", .monthly),
        .init("JetBrains", .annual),
        .init("Adobe Creative Cloud", .monthly, aliases: ["adobe", "creativecloud"], pricePoints: [.monthly("22.99"), .monthly("59.99")]),
        .init("Sketch", .annual),
        .init("Linear", .monthly),
        .init("Vercel", .monthly, pricePoints: [.monthly("20.00")]),
        .init("Netlify", .monthly, pricePoints: [.monthly("19.00")]),
        .init("DigitalOcean", .monthly),
        .init("Cloudflare", .monthly, pricePoints: [.monthly("20.00")]),
        .init("Sentry", .monthly, pricePoints: [.monthly("26.00")]),
        .init("Postman", .monthly),
        .init("Docker", .monthly),
        .init("Replit", .monthly, pricePoints: [.monthly("25.00")]),
        .init("Apple Developer Program", .annual, aliases: ["appledeveloper"], pricePoints: [.annual("99.00")]),
    ]

    static let ai: [CatalogEntry] = [
        .init("ChatGPT", .monthly, aliases: ["openai"], pricePoints: [.monthly("20.00"), .monthly("200.00")]),
        .init("Claude", .monthly, aliases: ["anthropic"], pricePoints: [.monthly("20.00"), .monthly("100.00")]),
        .init("Perplexity", .monthly, pricePoints: [.monthly("20.00")]),
        .init("Midjourney", .monthly, pricePoints: [.monthly("10.00"), .monthly("30.00")]),
        .init("GitHub Copilot", .monthly, aliases: ["copilot"], pricePoints: [.monthly("10.00"), .monthly("19.00")]),
        .init("ElevenLabs", .monthly, pricePoints: [.monthly("5.00"), .monthly("22.00")]),
        .init("Runway", .monthly, pricePoints: [.monthly("15.00")]),
        .init("Cursor", .monthly, pricePoints: [.monthly("20.00")]),
    ]

    static let gaming: [CatalogEntry] = [
        .init("Xbox Game Pass", .monthly, aliases: ["xbox", "gamepass"], pricePoints: [.monthly("11.99"), .monthly("19.99")]),
        .init("PlayStation Plus", .monthly, aliases: ["playstation", "psplus"], pricePoints: [.monthly("11.99"), .annual("79.99")]),
        .init("Nintendo Switch Online", .annual, aliases: ["nintendo"], pricePoints: [.annual("19.99"), .annual("49.99")]),
        .init("EA Play", .monthly, aliases: ["eaplay", "electronicarts"], pricePoints: [.monthly("5.99")]),
        .init("Ubisoft Plus", .monthly, aliases: ["ubisoft"]),
        .init("Apple Arcade", .monthly, aliases: ["applearcade"], pricePoints: [.monthly("6.99")]),
        .init("Discord Nitro", .monthly, aliases: ["discord"], pricePoints: [.monthly("9.99"), .annual("99.99")]),
        .init("Twitch", .monthly),
        .init("Roblox Premium", .monthly, aliases: ["roblox"]),
    ]

    static let fitness: [CatalogEntry] = [
        .init("Strava", .annual, pricePoints: [.monthly("11.99"), .annual("79.99")]),
        .init("Peloton", .monthly),
        .init("MyFitnessPal", .annual, aliases: ["myfitnesspal"]),
        .init("Calm", .annual, pricePoints: [.annual("69.99")]),
        .init("Headspace", .annual, pricePoints: [.monthly("12.99"), .annual("69.99")]),
        .init("Whoop", .annual),
        .init("Fitbit Premium", .monthly, aliases: ["fitbit"]),
        .init("Noom", .monthly),
        .init("Oura", .monthly, pricePoints: [.monthly("5.99")]),
    ]

    static let education: [CatalogEntry] = [
        .init("Duolingo", .annual, pricePoints: [.monthly("12.99"), .annual("83.88")]),
        .init("Coursera", .monthly, pricePoints: [.monthly("59.00")]),
        .init("Udemy", .monthly),
        .init("Skillshare", .annual),
        .init("MasterClass", .annual, aliases: ["masterclass"], pricePoints: [.annual("120.00")]),
        .init("Brilliant", .annual, pricePoints: [.annual("149.88")]),
        .init("Babbel", .annual),
        .init("LinkedIn Learning", .monthly, aliases: ["linkedinlearning"]),
    ]

    static let news: [CatalogEntry] = [
        .init("New York Times", .monthly, aliases: ["nytimes", "nyt"]),
        .init("Wall Street Journal", .monthly, aliases: ["wsj", "dowjones"]),
        .init("The Economist", .annual, aliases: ["economist"]),
        .init("Financial Times", .monthly, aliases: ["ft.com", "financialtimes"]),
        .init("Bloomberg", .monthly),
        .init("The Guardian", .monthly, aliases: ["guardian"]),
        .init("Medium", .monthly, pricePoints: [.monthly("5.00"), .annual("50.00")]),
        .init("Substack", .monthly),
    ]

    static let social: [CatalogEntry] = [
        .init("Tinder", .monthly),
        .init("Bumble", .monthly),
        .init("Hinge", .monthly),
        .init("X Premium", .monthly, aliases: ["twitterblue", "xpremium"], pricePoints: [.monthly("8.00")]),
        .init("LinkedIn Premium", .monthly, aliases: ["linkedinpremium"]),
        .init("Reddit Premium", .monthly, aliases: ["redditpremium"], pricePoints: [.monthly("5.99")]),
    ]

    static let commerce: [CatalogEntry] = [
        .init("Amazon Prime", .annual, aliases: ["amazonprime"], pricePoints: [.monthly("14.99"), .annual("139.00")]),
        .init("Uber One", .monthly, aliases: ["uberone"], pricePoints: [.monthly("9.99"), .annual("96.00")]),
        .init("DashPass", .monthly, aliases: ["doordash"], pricePoints: [.monthly("9.99")]),
        .init("Instacart Plus", .monthly, aliases: ["instacart"], pricePoints: [.monthly("9.99"), .annual("99.00")]),
        .init("Patreon", .monthly),
        .init("Squarespace", .annual),
        .init("Wix", .annual),
        .init("WordPress", .annual, aliases: ["automattic"]),
        .init("Shopify", .monthly, pricePoints: [.monthly("39.00")]),
        .init("Mailchimp", .monthly),
        .init("Zapier", .monthly, pricePoints: [.monthly("19.99")]),
        .init("Setapp", .monthly, pricePoints: [.monthly("9.99")]),
    ]
}
