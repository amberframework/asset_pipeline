// Named palette picker used by the explicit macOS swatch appearances.

import SwiftUI
import Foundation

#if os(macOS)
private struct SwatchPickerItem {
    let name: String
    let color: Color
    let colorPayload: String
}

struct SwatchPickerHost: View {
    @ObservedObject var storage: IntStorage
    let specification: String
    @State private var isPalettePresented = false

    private var appearance: String { values["appearance"] as? String ?? "swatch_button" }
    private var items: [SwatchPickerItem] {
        (values["swatches"] as? [[String: Any]] ?? []).compactMap { item in
            guard let name = item["name"] as? String,
                  let color = item["color"] as? String else { return nil }
            return SwatchPickerItem(
                name: name,
                color: SurfaceCraftModifiers.color(from: color),
                colorPayload: color
            )
        }
    }
    private var selectionRingColor: Color {
        SurfaceCraftModifiers.color(from: values["selectionRing"] as? String ?? "role:text-primary")
    }
    private var values: [String: Any] {
        guard let data = specification.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return result
    }
    private var selected: SwatchPickerItem? {
        guard storage.value >= 0 && storage.value < items.count else { return nil }
        return items[storage.value]
    }

    var body: some View {
        switch appearance {
        case "swatch_row":
            HStack(spacing: 9) {
                ForEach(items.indices, id: \.self) { index in
                    swatchButton(index: index)
                }
            }
            .accessibilityElement(children: .contain)
        case "named_popup":
            paletteButton {
                HStack(spacing: 7) {
                    Text(selected?.name ?? "Choose color")
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                }
            }
        case "bezel_lamp":
            paletteButton {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                        }
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .separatorColor).opacity(0.72))
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selected?.color ?? .clear)
                        .frame(width: 22, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.3), lineWidth: 1))
                }
                .frame(width: 36, height: 36)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(selected?.name ?? "No color selected")
                .accessibilityValue(selected?.colorPayload ?? "")
                .accessibilityIdentifier("surface-craft-bezel-lamp-indicator")
            }
        default:
            paletteButton {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 3).fill(selected?.color ?? .clear)
                        .frame(width: 18, height: 18)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(selected?.name ?? "No color selected")
                        .accessibilityValue(selected?.colorPayload ?? "")
                        .accessibilityIdentifier("surface-craft-swatch-button-indicator")
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    Image(systemName: "eyedropper").font(.system(size: 11))
                }
                .fixedSize(horizontal: true, vertical: true)
            }
        }
    }

    // A native palette popover preserves the selected-color chip inside Form
    // rows, where SwiftUI Menu can replace a custom label with a disclosure glyph.
    private func paletteButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button {
            isPalettePresented = true
        } label: {
            label()
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(nsColor: .separatorColor), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityLabel("Choose color, \(selected?.name ?? "none selected")")
        .accessibilityValue(selected?.colorPayload ?? "")
        .popover(isPresented: $isPalettePresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(items.indices, id: \.self) { index in
                    Button {
                        storage.binding.wrappedValue = index
                        isPalettePresented = false
                    } label: {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(items[index].color)
                                .frame(width: 16, height: 16)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                            Text(items[index].name)
                            Spacer(minLength: 12)
                            if index == storage.value { Image(systemName: "checkmark") }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(items[index].name)
                    .accessibilityValue(items[index].colorPayload)
                    .accessibilityIdentifier("surface-craft-menu-option-\(index)")
                    .accessibilityAddTraits(index == storage.value ? .isSelected : [])
                }
            }
            .padding(6)
            .frame(minWidth: 150)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func swatchButton(index: Int) -> some View {
        Button {
            storage.binding.wrappedValue = index
        } label: {
            Circle().fill(items[index].color)
                .frame(width: 21, height: 21)
                .overlay(Circle().stroke(index == storage.value ? selectionRingColor : Color.primary.opacity(0.2),
                                         lineWidth: index == storage.value ? 2 : 1))
                .padding(2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(items[index].name)
        .accessibilityValue(items[index].colorPayload)
        .accessibilityIdentifier("surface-craft-swatch-row-\(index)")
        .accessibilityAddTraits(index == storage.value ? .isSelected : [])
    }
}
#endif
