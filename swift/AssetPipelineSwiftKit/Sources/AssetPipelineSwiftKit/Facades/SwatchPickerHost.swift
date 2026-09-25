// Named palette picker used by the explicit macOS swatch appearances.

import SwiftUI
import Foundation

#if os(macOS)
private struct SwatchPickerItem {
    let name: String
    let color: Color
}

struct SwatchPickerHost: View {
    @ObservedObject var storage: IntStorage
    let specification: String

    private var appearance: String { values["appearance"] as? String ?? "swatch_button" }
    private var items: [SwatchPickerItem] {
        (values["swatches"] as? [[String: Any]] ?? []).compactMap { item in
            guard let name = item["name"] as? String,
                  let color = item["color"] as? String else { return nil }
            return SwatchPickerItem(name: name, color: SurfaceCraftModifiers.color(from: color))
        }
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
        case "named_popup":
            menuLabel {
                Text(selected?.name ?? "Choose color")
            }
        case "bezel_lamp":
            menuLabel {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor))
                        .frame(width: 34, height: 34)
                    RoundedRectangle(cornerRadius: 4).fill(selected?.color ?? .clear)
                        .frame(width: 19, height: 19)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.24), lineWidth: 1))
                }
            }
        default:
            menuLabel {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 3).fill(selected?.color ?? .clear)
                        .frame(width: 18, height: 18)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                    Image(systemName: "eyedropper").font(.system(size: 11))
                }
            }
        }
    }

    private func menuLabel<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Menu {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    storage.binding.wrappedValue = index
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(items[index].color).frame(width: 14, height: 14)
                        Text(items[index].name)
                        if index == storage.value { Image(systemName: "checkmark") }
                    }
                }
                .accessibilityAddTraits(index == storage.value ? .isSelected : [])
            }
        } label: {
            label()
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(nsColor: .separatorColor), lineWidth: 1))
                .accessibilityLabel("Choose color, \(selected?.name ?? "none selected")")
        }
        .menuStyle(.borderlessButton)
    }

    private func swatchButton(index: Int) -> some View {
        Button {
            storage.binding.wrappedValue = index
        } label: {
            Circle().fill(items[index].color)
                .frame(width: 21, height: 21)
                .overlay(Circle().stroke(index == storage.value ? Color.accentColor : Color.primary.opacity(0.2),
                                         lineWidth: index == storage.value ? 2 : 1))
                .padding(2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(items[index].name)
        .accessibilityAddTraits(index == storage.value ? .isSelected : [])
    }
}
#endif
