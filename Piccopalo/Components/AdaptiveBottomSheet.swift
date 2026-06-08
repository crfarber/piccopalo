import SwiftUI

enum AdaptiveBottomSheetMetrics {
    static var maxHeight: CGFloat {
        UIScreen.main.bounds.height * 2 / 3
    }

    static let navigationBarHeight: CGFloat = 52
}

private struct AdaptiveSheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    /// Rapporteert de natuurlijke hoogte van sheet-inhoud aan een omwikkelende `adaptiveBottomSheet`.
    func adaptiveSheetContentHeight() -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: AdaptiveSheetHeightKey.self,
                    value: geometry.size.height
                )
            }
        )
    }

    /// Sheet-hoogte op basis van inhoud, max 2/3 scherm. Bij overflow scrollt de inhoud.
    /// - Parameters:
    ///   - extraHeight: extra ruimte voor navigation bar of chrome buiten de gemeten inhoud
    ///   - wrapsContent: `true` als de sheet zelf moet scrollen; `false` als de inhoud al een `ScrollView` heeft
    func adaptiveBottomSheet(extraHeight: CGFloat = 0, wrapsContent: Bool = true) -> some View {
        modifier(AdaptiveBottomSheetModifier(extraHeight: extraHeight, wrapsContent: wrapsContent))
    }
}

private struct AdaptiveBottomSheetModifier: ViewModifier {
    let extraHeight: CGFloat
    let wrapsContent: Bool

    @State private var contentHeight: CGFloat = 0

    private var maxHeight: CGFloat {
        AdaptiveBottomSheetMetrics.maxHeight
    }

    private var totalHeight: CGFloat {
        contentHeight + extraHeight
    }

    private var sheetHeight: CGFloat {
        guard contentHeight > 0 else { return 240 }
        return min(totalHeight, maxHeight)
    }

    private var needsScroll: Bool {
        totalHeight > maxHeight
    }

    func body(content: Content) -> some View {
        Group {
            if wrapsContent {
                ScrollView {
                    content
                }
                .scrollDisabled(!needsScroll)
                .frame(height: contentHeight > 0 ? sheetHeight : nil)
            } else {
                content
                    .frame(maxHeight: maxHeight)
            }
        }
        .onPreferenceChange(AdaptiveSheetHeightKey.self) { height in
            guard height > 0, abs(height - contentHeight) > 0.5 else { return }
            contentHeight = height
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.Colors.background)
    }
}
