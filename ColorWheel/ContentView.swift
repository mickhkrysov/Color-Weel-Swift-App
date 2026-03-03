//
//  ContentView.swift
//  ColorWheel
//
//  Created by Mikhail Krysov on 02.03.2026.
//

import SwiftUI
import SwiftData

import SwiftUI

struct ContentView: View {
    var body: some View {
        ColorWheelScreen()
    }
}

struct ColorWheelScreen: View {
    // 0...1 hue (around the circle), 0...1 saturation (distance from center), 0...1 brightness
    @State private var hue: Double = 0.55
    @State private var sat: Double = 0.55
    @State private var brightness: Double = 1.0

    private let wheelSize: CGFloat = 520

    var selectedColor: Color {
        Color(hue: hue, saturation: sat, brightness: brightness)
    }

    var body: some View {
        ZStack {
            // Background like screenshot (soft light)
            LinearGradient(
                colors: [Color.white, Color(white: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 26) {
                Text("Pick a colour.")
                    .font(.system(size: 60, weight: .heavy, design: .default))
                    .foregroundStyle(.black)
                    .padding(.top, 30)
                    .padding(.leading, 20)

                // Wheel "card" area
                ZStack {
                    // soft shadow behind the wheel, like a raised disc
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

                    // Selection dot (black)
                    SelectionDot(hue: hue, sat: sat, wheelSize: wheelSize)
                }
                .frame(maxWidth: .infinity)

                // Slider like screenshot (pill with knob)
                VStack(spacing: 16) {
                    // preview strip (optional, looks nice and matches the vibe)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(selectedColor.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.black.opacity(0.10), lineWidth: 6)
                        )
                        .frame(height: 70)
                        .padding(.horizontal, 24)
                        .overlay(alignment: .trailing) {
                            // fake knob ring style
                            Circle()
                                .fill(Color.clear)
                                .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 6))
                                .frame(width: 64, height: 64)
                                .padding(.trailing, 30)
                        }

                    // Brightness slider (keeps the same look, but actually works)
                    Slider(value: $brightness, in: 0.0...1.0)
                        .tint(selectedColor) // if you want it always mint like screenshot, change to .mint
                        .padding(.horizontal, 34)
                }
                .padding(.bottom, 30)

                Spacer()
            }
        }
    }
}

/// Draws an HSV color wheel using an angular gradient and a radial "saturation" mask.
/// Also handles drag to update hue/sat.
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

                // Saturation: white in center -> transparent at edge (so center is pale/white-ish)
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

                        // angle -> hue (0..1)
                        var angle = atan2(dy, dx) // -pi..pi
                        if angle < 0 { angle += 2 * .pi } // 0..2pi
                        hue = Double(angle / (2 * .pi))
                    }
            )
        }
    }
}

/// Black dot positioned based on hue + saturation.
struct SelectionDot: View {
    let hue: Double
    let sat: Double
    let wheelSize: CGFloat

    var body: some View {
        let radius = wheelSize / 2
        let angle = CGFloat(hue) * 2 * .pi
        let r = CGFloat(sat) * radius

        // Convert polar -> cartesian (centered)
        let x = cos(angle) * r
        let y = sin(angle) * r

        Circle()
            .fill(Color.black)
            .frame(width: 18, height: 18)
            .offset(x: x, y: y)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}
