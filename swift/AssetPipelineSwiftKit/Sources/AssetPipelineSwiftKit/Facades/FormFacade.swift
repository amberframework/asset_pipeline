// FormFacade — SwiftUI Form { Section { ... } } bridge.
//
// Crystal flattens its (sections × fields) hierarchy into a flat
// `childViews` array. The facade slices it back into sections using the
// `sectionFieldCounts` array. Headers / footers come from the parallel
// `sectionHeaders` / `sectionFooters` arrays (one entry per section).
// Field labels come from `sectionFieldLabels`, flattened to match
// `childViews`.

import SwiftUI
import Foundation

@objc(APSKFormFacade)
public class FormFacade: NSObject {
    @objc public static func makeForm(
        childViews: [APSKPlatformView],
        overrides: FormOverrides
    ) -> APSKPlatformView {
        let counts = overrides.sectionFieldCounts.map { $0.intValue }
        let headers = overrides.sectionHeaders
        let footers = overrides.sectionFooters
        let labels = overrides.sectionFieldLabels
        #if os(macOS)
        let tabShapes = overrides.sectionTabShapes
        let tabIcons = overrides.sectionTabIcons
        let panelStyles = overrides.sectionPanelStyles
        let tabStyles = overrides.sectionTabStyles
        #else
        // iOS and Android keep the existing grouped Form appearance.
        let tabShapes: [String] = []
        let tabIcons: [String] = []
        let panelStyles: [String] = []
        let tabStyles: [String] = []
        #endif

        // Pre-compute slice offsets per section so the ForEach builder
        // body is O(1) per row.
        var offsets: [Int] = []
        var acc = 0
        for c in counts {
            offsets.append(acc)
            acc += c
        }

        var content: AnyView = AnyView(
            Form {
                ForEach(0..<counts.count, id: \.self) { sIdx in
                    let header = sIdx < headers.count ? headers[sIdx] : ""
                    let footer = sIdx < footers.count ? footers[sIdx] : ""
                    let off = offsets[sIdx]
                    let cnt = counts[sIdx]
                    let shape = sIdx < tabShapes.count ? tabShapes[sIdx] : ""
                    if shape.isEmpty {
                        Section {
                            ForEach(0..<cnt, id: \.self) { fIdx in
                                let absIdx = off + fIdx
                                let lbl = absIdx < labels.count ? labels[absIdx] : ""
                                if !lbl.isEmpty {
                                    LabeledContent(lbl) {
                                        APSKHostedChild(view: childViews[absIdx])
                                    }
                                } else {
                                    APSKHostedChild(view: childViews[absIdx])
                                }
                            }
                        } header: {
                            if !header.isEmpty { Text(header) }
                        } footer: {
                            if !footer.isEmpty { Text(footer) }
                        }
                    } else {
                        let panelStyle = sIdx < panelStyles.count ? panelStyles[sIdx] : "{}"
                        let tabStyle = sIdx < tabStyles.count ? tabStyles[sIdx] : "{}"
                        let icon = sIdx < tabIcons.count ? tabIcons[sIdx] : ""
                        Section {
                            let rows = VStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<cnt, id: \.self) { fIdx in
                                    let absIdx = off + fIdx
                                    let lbl = absIdx < labels.count ? labels[absIdx] : ""
                                    HStack(alignment: .center, spacing: 12) {
                                        if !lbl.isEmpty {
                                            Text(lbl)
                                            Spacer(minLength: 12)
                                        }
                                        APSKHostedChild(view: childViews[absIdx])
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .overlay(alignment: .bottom) {
                                        if fIdx + 1 < cnt {
                                            Rectangle()
                                                .fill(Color.primary.opacity(0.14))
                                                .frame(height: 0.5)
                                        }
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("surface-craft-form-row-\(sIdx)-\(fIdx)")
                                }
                            }
                            let panelContent = VStack(alignment: .leading, spacing: 0) {
                                if shape == "flush", !header.isEmpty {
                                    APSKTabbedHeader(
                                        title: header, icon: icon, shape: shape, style: tabStyle,
                                        identifier: "surface-craft-tab-\(sIdx)"
                                    )
                                }
                                rows
                            }
                            let styledPanel = SurfaceCraftModifiers.apply(
                                AnyView(panelContent.padding(8)), spec: panelStyle,
                                keycapStyle: nil, cornerRadius: 8, previewState: nil
                            )
                            styledPanel
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        } header: {
                            if !header.isEmpty, shape != "flush" {
                                let label = APSKTabbedHeader(
                                    title: header, icon: icon, shape: shape, style: tabStyle,
                                    identifier: "surface-craft-tab-\(sIdx)"
                                )
                                label
                            }
                        } footer: {
                            if !footer.isEmpty { Text(footer) }
                        }
                    }
                }
            }
        )

        // macOS defaults Form to .columns, which right-aligns labels into a
        // separate column that clips at narrow widths and drops the grouped
        // section chrome entirely. .grouped is the System Settings look and
        // matches what Form already renders on iOS — use it as the macOS
        // default.
        #if os(macOS)
        if #available(macOS 13.0, *) {
            let grouped = content.formStyle(.grouped)
            if tabShapes.contains(where: { !$0.isEmpty }) {
                content = AnyView(grouped.scrollContentBackground(.hidden).background(Color.clear))
            } else {
                content = AnyView(grouped)
            }
        }
        #endif

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}

#if os(macOS)
private struct APSKTabbedHeader: View {
    let title: String
    let icon: String
    let shape: String
    let style: String
    let identifier: String

    var body: some View {
        let content = HStack(spacing: 7) {
            if !icon.isEmpty { Image(systemName: icon).accessibilityHidden(true) }
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.leading, shape == "flush" ? 0 : 13)
        .padding(.trailing, shape == "angled" ? 24 : (shape == "flush" ? 0 : 13))
        .padding(.vertical, shape == "flush" ? 6 : 7)
        let styled = SurfaceCraftModifiers.apply(
            AnyView(content), spec: style, keycapStyle: nil, cornerRadius: 7,
            previewState: nil
        )
        styled
            .fixedSize(horizontal: true, vertical: false)
            .clipShape(TabbedTabShape(style: shape))
            .overlay(alignment: .bottom) {
                if shape == "flush" {
                    Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 0.5)
                }
            }
            .accessibilityIdentifier(identifier)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct TabbedTabShape: Shape {
    let style: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch style {
        case "angled":
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        case "rounded":
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 7))
            path.addQuadCurve(to: CGPoint(x: rect.minX + 7, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 7), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case "notched":
            let notch: CGFloat = 6
            path.move(to: CGPoint(x: rect.minX + notch, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + notch))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
            path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - notch))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + notch))
            path.closeSubpath()
        default:
            path.addRect(rect)
        }
        return path
    }
}
#else
private struct APSKTabbedHeader: View {
    let title: String
    let icon: String
    let shape: String
    let style: String
    let identifier: String

    var body: some View { Text(title) }
}
#endif
