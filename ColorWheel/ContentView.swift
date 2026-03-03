//
//  ContentView.swift
//  ColorWheel
//
//  Created by Iaroslava Krysova on 02.03.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Color Wheel")
                .font(.title)
                .bold()

            ZStack {
                // Wheel
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: wheelColors),
                            center: .center
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.15), lineWidth: 2)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(angle))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert touch point to angle around center
                                let center = CGPoint(x: 140, y: 140)
                                let dx = value.location.x - center.x
                                let dy = value.location.y - center.y
                                let radians = atan2(dy, dx) // -pi...pi
                                var degrees = radians * 180 / .pi
                                if degrees < 0 { degrees += 360 }
                                // Make the "pointer" at top (12 o'clock) feel natural
                                angle = degrees - 90
                            }
                    )

                // Pointer at top
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 6, height: 26)
                        .shadow(radius: 2)
                    Spacer()
                }
                .frame(width: 280, height: 280)
            }

            // Selected color preview (based on current angle)
            HStack(spacing: 14) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected")
                        .font(.headline)
                    Text(hueText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 24)
    }

    // Smooth wheel: repeat first color at end so it blends nicely
    private var wheelColors: [Color] {
        [
            .red, .yellow, .green, .cyan, .blue, .purple, .red
        ]
    }

    // Map angle -> hue (0...1)
    private var hue: Double {
        // pointer is at top (12 o'clock), so we undo -90 shift
        let normalized = (angle + 90).truncatingRemainder(dividingBy: 360)
        let fixed = normalized < 0 ? normalized + 360 : normalized
        return fixed / 360.0
    }

    private var selectedColor: Color {
        Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }

    private var hueText: String {
        let degrees = Int(round(hue * 360)) % 360
        return "Hue: \(degrees)°"
    }
}

#Preview {
    ContentView()
}
