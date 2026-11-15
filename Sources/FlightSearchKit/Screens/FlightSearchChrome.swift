import SwiftUI

struct FlightSearchColors {
    let canvas: Color
    let card: Color
    let field: Color
    let primaryText: Color
    let secondaryText: Color
    let accent = Color(red: 0.784, green: 0.063, blue: 0.180)

    init(scheme: ColorScheme) {
        if scheme == .dark {
            canvas = Color(red: 0.09, green: 0.08, blue: 0.08)
            card = Color(red: 0.16, green: 0.14, blue: 0.14)
            field = Color(red: 0.22, green: 0.19, blue: 0.19)
            primaryText = Color.white
            secondaryText = Color.white.opacity(0.68)
        } else {
            canvas = Color(red: 0.965, green: 0.949, blue: 0.933)
            card = Color.white
            field = Color(red: 0.949, green: 0.929, blue: 0.910)
            primaryText = Color(red: 0.12, green: 0.09, blue: 0.09)
            secondaryText = Color(red: 0.38, green: 0.32, blue: 0.32)
        }
    }
}

extension View {
    @ViewBuilder
    func flightSearchScrollsPastKeyboard() -> some View {
        #if os(iOS)
        self.scrollDismissesKeyboard(.interactively)
        #else
        self
        #endif
    }

    @ViewBuilder
    func flightSearchInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func flightSearchDisablesAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func flightSearchDragIndicator() -> some View {
        #if os(iOS)
        self.presentationDragIndicator(.visible)
        #else
        self
        #endif
    }

    @ViewBuilder
    func flightSearchKeyboardDismiss(_ dismiss: @escaping () -> Void) -> some View {
        #if os(iOS)
        self.toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done", action: dismiss)
            }
        }
        #else
        self
        #endif
    }
}
