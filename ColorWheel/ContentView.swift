//
//  ContentView.swift
//  ColorWheel
//
//  Created by Mikhail Krysov on 02.03.2026.
//

import SwiftUI
import SwiftData

enum PaletteType: String, CaseIterable, Identifiable {
    case monochromatic = "Monochromatic"
    case analogous = "Analogous"
    case complementary = "Complementary"
    case triadic = "Triadic"
    case splitComplementary = "Split-Complementary"

    var id: String { rawValue }
}

struct HSV: Equatable {
    var h: Double
    var s: Double
    var v: Double
}

func wrapHue(_ h: Double) -> Double {
    var x = h.truncatingRemainder(dividingBy: 1.0)
    if x < 0 { x += 1.0 }
    return x
}

func clamp01(_ x: Double) -> Double { min(1.0, max(0.0, x)) }

func makePalette(base: HSV, type: PaletteType) -> [HSV] {
    // Hue offsets (in turns; 1.0 = 360)
    let deg30 = 30.0 / 360.0
    let deg120 = 120.0 / 360.0
    let deg180 = 180.0 / 360.0

    switch type {
    case .monochromatic:
        // Same hue; vary s and v a bit (5 colors)
        return [
            base,
            HSV(h: base.h, s: clamp01(base.s * 0.85), v: clamp01(base.v * 1.00)),
            HSV(h: base.h, s: clamp01(base.s * 1.00), v: clamp01(base.v * 0.85)),
            HSV(h: base.h, s: clamp01(base.s * 0.65), v: clamp01(base.v * 0.95)),
            HSV(h: base.h, s: clamp01(base.s * 1.00), v: clamp01(base.v * 0.70)),
        ]

    case .analogous:
        // base and neighbors around it
        return [
            HSV(h: wrapHue(base.h - 2*deg30), s: base.s, v: base.v),
            HSV(h: wrapHue(base.h - deg30),  s: base.s, v: base.v),
            base,
            HSV(h: wrapHue(base.h + deg30),  s: base.s, v: base.v),
            HSV(h: wrapHue(base.h + 2*deg30), s: base.s, v: base.v),
        ]

    case .complementary:
        // Base and opposite
        //add lighter/darker
        let comp = HSV(h: wrapHue(base.h + deg180), s: base.s, v: base.v)
        return [
            base,
            HSV(h: base.h, s: clamp01(base.s * 0.85), v: clamp01(base.v * 1.00)),
            comp,
            HSV(h: comp.h, s: clamp01(comp.s * 0.85), v: clamp01(comp.v * 1.00)),
            HSV(h: comp.h, s: clamp01(comp.s * 1.00), v: clamp01(comp.v * 0.80)),
        ]

    case .triadic:
        // base + 2 triad points;
        let t1 = HSV(h: wrapHue(base.h + deg120), s: base.s, v: base.v)
        let t2 = HSV(h: wrapHue(base.h - deg120), s: base.s, v: base.v)
        return [
            base,
            t1,
            t2,
            HSV(h: base.h, s: clamp01(base.s * 0.70), v: clamp01(base.v * 0.95)),
            HSV(h: t1.h,  s: clamp01(t1.s * 0.70),  v: clamp01(t1.v * 0.95)),
        ]

    case .splitComplementary:
        // complement ± 30°
        let c1 = HSV(h: wrapHue(base.h + deg180 - deg30), s: base.s, v: base.v)
        let c2 = HSV(h: wrapHue(base.h + deg180 + deg30), s: base.s, v: base.v)
        return [
            base,
            c1,
            c2,
            HSV(h: base.h, s: clamp01(base.s * 0.75), v: clamp01(base.v * 0.95)),
            HSV(h: c1.h,  s: clamp01(c1.s * 0.75),  v: clamp01(c1.v * 0.95)),
        ]
    }
}

struct ContentView: View {
    var body: some View {
        ColorWheelScreen()
    }
}

struct ColorWheelScreen: View {
    @State private var hue: Double = 0.55
    @State private var sat: Double = 0.55
    @State private var brightness: Double = 1.0

    private let wheelSize: CGFloat = 300

    var selectedColor: Color {
        Color(hue: hue, saturation: sat, brightness: brightness)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(white: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 26) {
                Text(" Pick a colour.")
                    .font(.system(size: 40, weight: .heavy, design: .default))
                    .foregroundStyle(.black)
                    .padding(.top, 30)
                    .padding(.leading, 20)

                // Wheel "card" area
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: wheelSize + 40, height: wheelSize + 40)
                        .shadow(color: Color.black.opacity(0.10), radius: 28, x: 0, y: 18)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)

                    // subtle outer rim
                    Circle()
                        .stroke(Color.black.opacity(0.12), lineWidth: 12)
                        .frame(width: wheelSize + 10, height: wheelSize + 10)

                    // Actual HSV wheel
                    ColorWheel(
                        hue: $hue,
                        sat: $sat,
                        brightness: brightness
                    )
                    .frame(width: wheelSize, height: wheelSize)
                    .clipShape(Circle())

                    // Selection dot
                    SelectionDot(hue: hue, sat: sat, wheelSize: wheelSize)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    // Brightness slider
                    Slider(value: $brightness, in: 0.0...1.0)
                        .tint(selectedColor)
                        .padding(.horizontal, 34)
                    // preview strip
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(selectedColor.opacity(1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.black.opacity(0.10), lineWidth: 5)
                        )
                    PaletteView(base: HSV(h: hue, s: sat, v: brightness))
                        .frame(height: 70)
                        .padding(.horizontal, 24)
                        .overlay(alignment: .trailing) {
                        }
                    //HEX Code
                    Text(selectedColor.toHex())
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .padding()
                }
                .padding(.bottom, 30)

                Spacer()
            }
        }
    }
}

struct ColorWheel: View {
    @Binding var hue: Double
    @Binding var sat: Double
    let brightness: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: radius, y: radius)

            ZStack {
                // Hue around the circle
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: stride(from: 0.0, through: 1.0, by: 0.02).map {
                                Color(hue: $0, saturation: 1, brightness: brightness)
                            }),
                            center: .center
                        )
                    )

                // Saturation: white in center and saturated at edge (so center is pale/white-ish)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                    .blendMode(.screen)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.location.x - center.x
                        let dy = value.location.y - center.y
                        let dist = sqrt(dx*dx + dy*dy)
                        // clamp to circle
                        let clampedDist = min(dist, radius)
                        sat = Double(clampedDist / radius)
                        // angle goes to hue (0..1)
                        var angle = atan2(dy, dx) // -pi..pi
                        if angle < 0 { angle += 2 * .pi } // 0..2pi
                        hue = Double(angle / (2 * .pi))
                    }
            )
        }
    }
}

struct SelectionDot: View {
    let hue: Double
    let sat: Double
    let wheelSize: CGFloat

    var body: some View {
        let radius = wheelSize / 2
        let angle = CGFloat(hue) * 2 * .pi
        let r = CGFloat(sat) * radius

        // Convert polar -> cartesian
        let x = cos(angle) * r
        let y = sin(angle) * r

        Circle()
            .fill(Color.black)
            .frame(width: 18, height: 18)
            .offset(x: x, y: y)
            .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
    }
}

// displays the HEX code
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
        return String(format: "#%06X", rgb)
    }
}
//different palletes
struct PaletteView: View {
    let base: HSV
    @State private var type: PaletteType = .monochromatic

    var palette: [HSV] { makePalette(base: base, type: type) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Palette", selection: $type) {
                ForEach(PaletteType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                ForEach(Array(palette.enumerated()), id: \.offset) { _, hsv in
                    let c = Color(hue: hsv.h, saturation: hsv.s, brightness: hsv.v)

                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(c)
                            .frame(height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )

                        Text(c.toHex())
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

