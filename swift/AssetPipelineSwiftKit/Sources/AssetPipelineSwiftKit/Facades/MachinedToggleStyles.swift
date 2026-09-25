// Explicit macOS ToggleStyle implementations used by ToggleFacade.

import SwiftUI

#if os(macOS)
struct PillToggleStyle: ToggleStyle {
    let track: Color
    let knob: Color
    let on: Color
    let lamp: Color

    func makeBody(configuration: Configuration) -> some View {
        MachinedToggleBody(configuration: configuration, appearance: .pill,
                           track: track, knob: knob, on: on, lamp: lamp)
    }
}

struct RockerToggleStyle: ToggleStyle {
    let track: Color
    let knob: Color
    let on: Color
    let lamp: Color

    func makeBody(configuration: Configuration) -> some View {
        MachinedToggleBody(configuration: configuration, appearance: .rocker,
                           track: track, knob: knob, on: on, lamp: lamp)
    }
}

struct SlideToggleStyle: ToggleStyle {
    let track: Color
    let knob: Color
    let on: Color
    let lamp: Color

    func makeBody(configuration: Configuration) -> some View {
        MachinedToggleBody(configuration: configuration, appearance: .slide,
                           track: track, knob: knob, on: on, lamp: lamp)
    }
}

struct LampPillToggleStyle: ToggleStyle {
    let track: Color
    let knob: Color
    let on: Color
    let lamp: Color

    func makeBody(configuration: Configuration) -> some View {
        MachinedToggleBody(configuration: configuration, appearance: .lampPill,
                           track: track, knob: knob, on: on, lamp: lamp)
    }
}

private struct MachinedToggleBody: View {
    enum Appearance { case pill, rocker, slide, lampPill }

    let configuration: ToggleStyleConfiguration
    let appearance: Appearance
    let track: Color
    let knob: Color
    let on: Color
    let lamp: Color

    var body: some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 10)
                control
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(configuration.isOn ? Text("On") : Text("Off"))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch appearance {
        case .pill:
            Capsule()
                .fill(configuration.isOn ? on : track)
                .frame(width: 34, height: 20)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle().fill(knob).frame(width: 16, height: 16).padding(2)
                }
        case .rocker:
            RoundedRectangle(cornerRadius: 6)
                .fill(track)
                .frame(width: 40, height: 20)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(configuration.isOn ? on : knob)
                        .frame(width: 18, height: 16)
                        .overlay {
                            Text(configuration.isOn ? "I" : "O")
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundStyle(configuration.isOn ? Color.primary : Color.secondary)
                        }
                        .padding(2)
                        .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                }
        case .slide:
            RoundedRectangle(cornerRadius: 7)
                .fill(track)
                .frame(width: 38, height: 14)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(configuration.isOn ? on : lamp.opacity(0.55))
                        .frame(width: 4, height: 4)
                        .padding(.leading, 5)
                }
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(knob)
                        .frame(width: 20, height: 20)
                        .overlay {
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Rectangle().fill(Color.primary.opacity(0.2)).frame(width: 1, height: 12)
                                }
                            }
                        }
                        .padding(.horizontal, -1)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black.opacity(0.14), lineWidth: 1))
                .padding(.vertical, 3)
        case .lampPill:
            Capsule()
                .fill(track)
                .frame(width: 50, height: 20)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(configuration.isOn ? lamp : Color.primary.opacity(0.22))
                        .frame(width: 8, height: 8)
                        .padding(.leading, 7)
                }
                .overlay(alignment: .leading) {
                    Circle().fill(knob).frame(width: 16, height: 16)
                        .offset(x: configuration.isOn ? 28 : 18)
                        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                }
        }
    }
}
#endif
