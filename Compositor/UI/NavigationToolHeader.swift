import SwiftUI

struct NavigationToolHeader: View {
    @Bindable var session: EditorSession
    @State private var zoomText = ""
    @State private var displayedZoomText = ""
    @State private var stepper = ArrowStepper()
    @FocusState private var editingZoom: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(session.tool == .hand ? L10n.tr("Pan") : L10n.tr("Zoom")).font(ToolHeaderStyle.titleFont)
            if session.tool == .zoom {
                TextField(L10n.tr("Zoom"), text: $zoomText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .multilineTextAlignment(.trailing)
                    .focused($editingZoom)
                    .onSubmit { releaseFocus() }
                    .onExitCommand { releaseFocus() }
                    .onChange(of: editingZoom) { _, focused in if !focused { applyZoom() } }
                    .arrowSteps(editing: editingZoom, stepper: stepper,
                                value: { LocalizedNumber.parse(zoomText.replacingOccurrences(of: L10n.tr("%"), with: "")) ?? Double(session.viewport.zoom * 100) },
                                change: { step($0) })
                    .accessibilityLabel(L10n.tr("Zoom percentage"))
                    .help(L10n.tr("Zoom percentage (0.1–3200%). Press Return to apply."))
                    .disabled(session.document == nil || session.showsBusy)
                    .unitSuffix(L10n.tr("%"), scrubValue: Binding<Double>(
                        get: { Double(session.viewport.zoom * 100) }, set: { step($0) }),
                        sensitivity: 1, range: 0.1...3200)
            }
            Spacer()
        }
        .padding(.horizontal, 18).toolHeaderBar()
        .onAppear { syncZoom() }
        .onChange(of: session.viewport.zoom) { _, _ in
            if !editingZoom { syncZoom() }
        }
    }

    /// Up and Down nudge the zoom by one percent, or ten with Shift.
    private func step(_ percent: Double) {
        zoomText = LocalizedNumber.format(min(3200, max(0.1, percent)))
        applyZoom()
    }
    /// Losing focus applies the zoom; the canvas takes the focus back so a tool's key works straight away.
    private func releaseFocus() {
        editingZoom = false
        session.canvasFocusRequest += 1
    }
    private func applyZoom() {
        defer { syncZoom() }
        guard zoomText != displayedZoomText else { return }
        let text = zoomText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: L10n.tr("%"), with: "")
        if let value = LocalizedNumber.parse(text), value.isFinite, value > 0, !session.isProjectBusy {
            session.zoom(to: CGFloat(value / 100))
        }
    }

    private func syncZoom() {
        zoomText = LocalizedNumber.format(Double(session.viewport.zoom * 100))
        displayedZoomText = zoomText
    }
}
