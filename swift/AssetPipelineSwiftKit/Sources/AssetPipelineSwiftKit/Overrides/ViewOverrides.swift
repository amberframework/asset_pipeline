// ViewOverrides — the common @objc override carrier shared by every widget.
//
// Every field is nullable (`UIColor?`, `NSNumber?`, `String?`) and defaults
// to `nil`. A `nil` field means "the Crystal-side `UI::View` left this
// property at its type default — apply the SwiftUI default treatment."
// A non-nil field means the Crystal author explicitly set the property,
// so the corresponding modifier MUST be applied (see CommonModifiers.apply).
//
// All numeric fields are `NSNumber?` rather than `Double?` so they bridge
// cleanly to ObjC where `Double?` is not representable.
//
// This file is the sole owner of `APSKPlatformView`. HostingHelpers.swift
// imports the typealias from here; declaring it in two places is a
// duplicate-typealias error (see §5.5 / implementation.md line 701).

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
public typealias APSKPlatformView = UIView
public typealias APSKPlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias APSKPlatformView = NSView
public typealias APSKPlatformColor = NSColor
#endif

@objc(APSKViewOverrides)
public class ViewOverrides: NSObject {
    @objc public var backgroundColor: APSKPlatformColor? = nil    // nil = SwiftUI default
    @objc public var foregroundColor: APSKPlatformColor? = nil
    @objc public var cornerRadius: NSNumber? = nil                 // pt
    @objc public var paddingTop: NSNumber? = nil
    @objc public var paddingLeading: NSNumber? = nil
    @objc public var paddingBottom: NSNumber? = nil
    @objc public var paddingTrailing: NSNumber? = nil
    @objc public var borderWidth: NSNumber? = nil                  // pt
    @objc public var borderColor: APSKPlatformColor? = nil
    @objc public var shadowRadius: NSNumber? = nil
    @objc public var shadowColor: APSKPlatformColor? = nil
    @objc public var shadowOffsetX: NSNumber? = nil
    @objc public var shadowOffsetY: NSNumber? = nil
    @objc public var opacity: NSNumber? = nil                      // 0..1; nil = 1
    @objc public var hidden: NSNumber? = nil                       // bool-as-int
    @objc public var minWidth: NSNumber? = nil
    @objc public var minHeight: NSNumber? = nil
    @objc public var maxWidth: NSNumber? = nil
    @objc public var maxHeight: NSNumber? = nil
    @objc public var accessibilityIdentifier: String? = nil
    // Renamed from `accessibilityLabel` to avoid colliding with the
    // `NSObject`-supplied `UIAccessibility.accessibilityLabel` selector on
    // iOS slices, which produced the iter-1 "setter conflicts with
    // superclass" compile error. The explicit `@objc(apskAccessibilityLabel)`
    // pins the Objective-C selector so the Crystal Populator addresses an
    // unambiguous setter (`setApskAccessibilityLabel:`).
    @objc(apskAccessibilityLabel) public var apskAccessibilityLabel: String? = nil

    @objc public override init() { super.init() }
}
