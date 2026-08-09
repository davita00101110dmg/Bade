import DesignSystem
import Localization
import SwiftUI

struct ExportGuideCard: View {
    @Environment(\.badeTheme) private var theme
    @State private var bank: SupportedBank = .bog

    var body: some View {
        BadeCard {
            VStack(alignment: .leading, spacing: .lg) {
                HStack(alignment: .top) {
                    Text(.welcome.guideTitle)
                        .font(.badeHeadline)
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: .sm)
                    BankPicker(bank: $bank)
                }

                VStack(alignment: .leading, spacing: .sm) {
                    ForEach(Array(bank.exportSteps.enumerated()), id: \.offset) { index, step in
                        BadeNumberedStep(index + 1, Text(step))
                    }
                }
                .badeAnimation(.badeSelection, value: bank)
            }
        }
    }
}

private struct BankPicker: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var bank: SupportedBank
    @Namespace private var selection

    var body: some View {
        HStack(spacing: .xxs) {
            ForEach(SupportedBank.allCases) { option in
                let isSelected = option == bank
                Button {
                    withBadeAnimation(.badeSelection, reduceMotion: reduceMotion) { bank = option }
                } label: {
                    Text(verbatim: option.rawValue)
                        .font(.badeLabel)
                        .foregroundStyle(isSelected ? theme.ink : theme.inkMuted)
                        .padding(.horizontal, .sm)
                        .padding(.vertical, .xs)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: BadeRadius.sm, style: .continuous)
                                    .fill(theme.surfaceRaised)
                                    .matchedGeometryEffect(id: "bank", in: selection)
                            }
                        }
                }
                .buttonStyle(.plain)
                .frame(minWidth: BadeLayout.minimumTapTarget, minHeight: BadeLayout.minimumTapTarget)
                .contentShape(.rect)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.xxs)
        .background(
            RoundedRectangle(cornerRadius: BadeRadius.md, style: .continuous)
                .fill(theme.surfaceSunken))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(.welcome.guideBankPicker))
    }
}
