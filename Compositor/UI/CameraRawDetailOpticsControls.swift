import AppKit
import SwiftUI

struct CameraRawDetailControls: View {
    @Bindable var session: EditorSession
    private var settings: FilterSettings { session.filterEdit?.settings ?? FilterSettings() }
    private var raw: CameraRawSettings { settings.cameraRaw }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Sharpening")).font(.subheadline)
            sharpenSlider(L10n.tr("Amount"), \.sharpenAmount, range: CameraRawDetailSettings.sharpenAmountRange, decimals: 0, reset: 0,
                          help: L10n.tr("Controls how strong the sharpening is."))
            sharpenSlider(L10n.tr("Radius"), \.sharpenRadius, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 10,
                          help: L10n.tr("How far from each edge the sharpening reaches, in pixels."))
            sharpenSlider(L10n.tr("Detail"), \.sharpenDetail, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 25,
                          help: L10n.tr("Emphasizes fine texture over broader edges."))
            sharpenSlider(L10n.tr("Masking"), \.sharpenMasking, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 0,
                          maskingPreview: true, help: L10n.tr("Limits sharpening to stronger edges. Hold Option to see the mask."))
            Text(L10n.tr("Noise Reduction")).font(.subheadline)
            slider(L10n.tr("Luminance"), \.noiseLuminance, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 0,
                   help: L10n.tr("Smooths grain and noise in brightness."))
            Group {
                slider(L10n.tr("Luminance Detail"), \.noiseLuminanceDetail, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 50,
                       help: L10n.tr("Preserves fine texture while luminance noise is reduced."))
                slider(L10n.tr("Luminance Contrast"), \.noiseLuminanceContrast, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 0,
                       help: L10n.tr("Keeps local contrast after luminance smoothing."))
            }
            .opacity(raw.detail.noiseLuminance > 0 ? 1 : 0.45)
            .disabled(raw.detail.noiseLuminance <= 0)
            slider(L10n.tr("Color"), \.noiseColor, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 0,
                   help: L10n.tr("Smooths colored speckles."))
            Group {
                slider(L10n.tr("Color Detail"), \.noiseColorDetail, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 50,
                       help: L10n.tr("Preserves colored edges while color noise is reduced."))
                slider(L10n.tr("Color Smoothness"), \.noiseColorSmoothness, range: CameraRawDetailSettings.unitRange, decimals: 0, reset: 50,
                       help: L10n.tr("Makes the color smoothing softer or tighter."))
            }
            .opacity(raw.detail.noiseColor > 0 ? 1 : 0.45)
            .disabled(raw.detail.noiseColor <= 0)
        }
    }

    private func sharpenSlider(_ title: String, _ key: WritableKeyPath<CameraRawDetailSettings, Double>, range: ClosedRange<Double>,
                               decimals: Int, reset: Double, maskingPreview: Bool = false, help: String) -> some View {
        let step = pow(10, Double(decimals))
        let value = raw.detail[keyPath: key]
        return HStack(spacing: 10) {
            Text(title).frame(minWidth: CameraRawControls.labelWidth, alignment: .leading).help(help)
                .scrubbable(sensitivity: 1 / step,
                            value: Binding(get: { raw.detail[keyPath: key] },
                                           set: { assignDetail(key, $0, maskingPreview: false) }), range: range)
            CameraRawSlider(value: value, range: range, track: .plain, help: help,
                            onChange: { rawValue in
                                let stepped = (rawValue * step).rounded() / step
                                assignDetail(key, stepped, maskingPreview: maskingPreview)
                            },
                            onReset: { assignDetail(key, reset, maskingPreview: false) })
            TextField(title, value: Binding(get: { raw.detail[keyPath: key] }, set: { assignDetail(key, $0, maskingPreview: false) }),
                      format: .number.precision(.fractionLength(0...decimals)))
                .frame(width: 56).textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing).help(help)
        }
    }

    private func slider(_ title: String, _ key: WritableKeyPath<CameraRawDetailSettings, Double>, range: ClosedRange<Double>,
                        decimals: Int, reset: Double, help: String) -> some View {
        sharpenSlider(title, key, range: range, decimals: decimals, reset: reset, help: help)
    }

    private func assignDetail(_ key: WritableKeyPath<CameraRawDetailSettings, Double>, _ newValue: Double, maskingPreview: Bool) {
        if maskingPreview {
            session.filterEdit?.cameraRawSharpenMask = NSEvent.modifierFlags.contains(.option)
        } else {
            session.filterEdit?.cameraRawSharpenMask = false
        }
        update { settings in settings.cameraRaw.detail[keyPath: key] = newValue }
    }

    private func update(_ change: (inout FilterSettings) -> Void) {
        var value = settings
        change(&value)
        session.updateFilter(value, preview: session.filterEdit?.preview ?? true)
    }
}

struct CameraRawOpticsControls: View {
    @Bindable var session: EditorSession
    private var settings: FilterSettings { session.filterEdit?.settings ?? FilterSettings() }
    private var raw: CameraRawSettings { settings.cameraRaw }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(L10n.tr("Remove Chromatic Aberration"), isOn: binding(\.removeChromaticAberration))
                .help(L10n.tr("Pulls red and blue fringes apart toward the center to reduce color edging."))
            Toggle(L10n.tr("Enable Lens Profile Corrections"), isOn: binding(\.enableLensProfile))
                .help(L10n.tr("Applies generic profile strength when camera metadata is not available."))
            if raw.optics.enableLensProfile {
                Text(L10n.tr("No lens metadata on this layer. Profile sliders set generic correction strength."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                opticsSlider(L10n.tr("Distortion"), \.profileDistortion, range: CameraRawOpticsSettings.unitRange, reset: 100,
                             help: L10n.tr("How much of the profile distortion correction is applied."))
                opticsSlider(L10n.tr("Vignetting"), \.profileVignetting, range: CameraRawOpticsSettings.unitRange, reset: 100,
                             help: L10n.tr("How much of the profile vignetting correction is applied."))
            }
            Text(L10n.tr("Manual")).font(.subheadline)
            opticsSlider(L10n.tr("Distortion"), \.distortion, range: CameraRawOpticsSettings.toneRange, reset: 0,
                         help: L10n.tr("Straightens barrel or pincushion bending."))
            HStack(spacing: 10) {
                Text(L10n.tr("Defringe")).frame(minWidth: CameraRawControls.labelWidth, alignment: .leading)
                    .help(L10n.tr("Click a purple or green fringe to set its hue range."))
                Button {
                    session.filterEdit?.samplesDefringe.toggle()
                    session.brushRevision += 1
                } label: {
                    Image(systemName: "eyedropper")
                }
                .buttonStyle(.borderless)
                .tint(session.filterEdit?.samplesDefringe == true ? Color.accentColor : Color.secondary)
                .help(L10n.tr("Click a purple or green fringe to set its hue range."))
            }
            if session.filterEdit?.samplesDefringe == true {
                Text(L10n.tr("Click the fringe on the layer. Click the eyedropper again to stop."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            opticsSlider(L10n.tr("Purple Amount"), \.purpleAmount, range: CameraRawOpticsSettings.unitRange, reset: 0,
                         help: L10n.tr("Weakens purple fringes inside the purple hue range."))
            hueRange(L10n.tr("Purple Hue"), low: \.purpleHueLow, high: \.purpleHueHigh,
                     help: L10n.tr("Hue range where purple defringe runs."))
            opticsSlider(L10n.tr("Green Amount"), \.greenAmount, range: CameraRawOpticsSettings.unitRange, reset: 0,
                         help: L10n.tr("Weakens green fringes inside the green hue range."))
            hueRange(L10n.tr("Green Hue"), low: \.greenHueLow, high: \.greenHueHigh,
                     help: L10n.tr("Hue range where green defringe runs."))
            opticsSlider(L10n.tr("Vignetting"), \.vignetteAmount, range: CameraRawOpticsSettings.toneRange, reset: 0,
                         help: L10n.tr("Brightens or darkens the corners to counter lens falloff."))
            opticsSlider(L10n.tr("Midpoint"), \.vignetteMidpoint, range: CameraRawOpticsSettings.unitRange, reset: 50,
                         help: L10n.tr("Moves the vignette correction inward or outward."))
        }
    }

    private func binding(_ key: WritableKeyPath<CameraRawOpticsSettings, Bool>) -> Binding<Bool> {
        Binding(get: { raw.optics[keyPath: key] }, set: { newValue in update { $0.cameraRaw.optics[keyPath: key] = newValue } })
    }

    private func opticsSlider(_ title: String, _ key: WritableKeyPath<CameraRawOpticsSettings, Double>, range: ClosedRange<Double>,
                              reset: Double, help: String) -> some View {
        let value = raw.optics[keyPath: key]
        return HStack(spacing: 10) {
            Text(title).frame(minWidth: CameraRawControls.labelWidth, alignment: .leading).help(help)
                .scrubbable(sensitivity: 1,
                            value: Binding(get: { raw.optics[keyPath: key] },
                                           set: { newValue in update { $0.cameraRaw.optics[keyPath: key] = newValue } }), range: range)
            CameraRawSlider(value: value, range: range, track: .plain, help: help,
                            onChange: { rawValue in
                                let stepped = range.lowerBound < 0 ? rawValue : rawValue.rounded()
                                update { $0.cameraRaw.optics[keyPath: key] = stepped }
                            },
                            onReset: { update { $0.cameraRaw.optics[keyPath: key] = reset } })
            TextField(title, value: Binding(get: { raw.optics[keyPath: key] }, set: { newValue in update { $0.cameraRaw.optics[keyPath: key] = newValue } }),
                      format: .number.precision(.fractionLength(0)))
                .frame(width: 56).textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing).help(help)
        }
    }

    private func hueRange(_ title: String, low: WritableKeyPath<CameraRawOpticsSettings, Double>,
                          high: WritableKeyPath<CameraRawOpticsSettings, Double>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary).help(help)
            HStack(spacing: 8) {
                Text(L10n.tr("Low")).font(.caption2).help(L10n.tr("Start of the hue range, in degrees."))
                CameraRawSlider(value: raw.optics[keyPath: low], range: CameraRawOpticsSettings.hueRange, track: .plain,
                                help: L10n.tr("Start of the hue range, in degrees."),
                                onChange: { value in update { $0.cameraRaw.optics[keyPath: low] = value.rounded() } },
                                onReset: { update { $0.cameraRaw.optics[keyPath: low] = low == \CameraRawOpticsSettings.purpleHueLow ? 270 : 60 } })
                Text(L10n.tr("High")).font(.caption2).help(L10n.tr("End of the hue range, in degrees."))
                CameraRawSlider(value: raw.optics[keyPath: high], range: CameraRawOpticsSettings.hueRange, track: .plain,
                                help: L10n.tr("End of the hue range, in degrees."),
                                onChange: { value in update { $0.cameraRaw.optics[keyPath: high] = value.rounded() } },
                                onReset: { update { $0.cameraRaw.optics[keyPath: high] = low == \CameraRawOpticsSettings.purpleHueLow ? 310 : 120 } })
            }
        }
        .padding(.leading, CameraRawControls.labelWidth + 10)
    }

    private func update(_ change: (inout FilterSettings) -> Void) {
        var value = settings
        change(&value)
        session.updateFilter(value, preview: session.filterEdit?.preview ?? true)
    }
}
