import DesignSystem
import Localization
import SwiftUI

/// Bank-agnostic by constraint 6: every mobile banking app exports the same way, and naming two
/// of them told the rest of the world the app was not for them.
struct ExportGuideCard: View {
    @Environment(\.badeTheme) private var theme

    var body: some View {
        BadeCard {
            VStack(alignment: .leading, spacing: .lg) {
                Text(.welcome.guideTitle)
                    .font(.badeHeadline)
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: .sm) {
                    ForEach(Array(LocalizedStringResource.welcome.guideSteps.enumerated()), id: \.offset) {
                        index, step in
                        BadeNumberedStep(index + 1, Text(step))
                    }
                }
            }
        }
    }
}
