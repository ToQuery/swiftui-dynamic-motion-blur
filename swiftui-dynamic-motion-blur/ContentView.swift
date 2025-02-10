//
//  ContentView.swift
//  swiftui-dynamic-motion-blur
//
//  Created by ToQuery on 2025/2/10.
//

import SwiftUI

class CircleAnimator: ObservableObject {
    class Circle: Identifiable {
        internal init(position: CGPoint, color: Color) {
            self.position = position
            self.color = color
        }

        var position: CGPoint
        let id = UUID().uuidString
        let color: Color
    }

    @Published
    private(set) var circles: [Circle] = []

    init(colors: [Color]) {
        circles = colors.map { color in
            Circle(position: CircleAnimator.generateRandomPosition(), color: color)
        }
    }

    func animate() {
        objectWillChange.send()
        for circle in circles {
            circle.position = CircleAnimator.generateRandomPosition()
        }
    }

    static func generateRandomPosition() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0 ... 1), y: CGFloat.random(in: 0 ... 1))
    }
}

struct ContentView: View {
    private enum AnimationProperties {
        static let animationSpeed: Double = 4
        static let timerDuration: TimeInterval = 3
        static let blurRadius: CGFloat = 130
    }

    @State private var timer = Timer.publish(every: AnimationProperties.timerDuration, on: .main, in: .common).autoconnect()

    @ObservedObject
    private var animator = CircleAnimator(colors: GradientColors.all)

    var body: some View {
        ZStack {
            ZStack {
                ForEach(animator.circles) { Circle in
                    MovingCircle(originOffset: Circle.position)
                        .foregroundColor(Circle.color)
                }
            }
            .blur(radius: AnimationProperties.blurRadius)
        }
        .background(GradientColors.backgroundColor)
        .onDisappear(perform: {
            timer.upstream.connect().cancel()
        })
        .onAppear(perform: {
            animateCircles()
            timer = Timer.publish(every: AnimationProperties.timerDuration, on: .main,
                                  in: .common).autoconnect()
        })
        .onReceive(timer) { _ in
            animateCircles()
        }
    }

    private func animateCircles() {
        withAnimation(.easeInOut(duration: AnimationProperties.animationSpeed)) {
            animator.animate()
        }
    }
}

private struct MovingCircle: Shape {
    var originOffset: CGPoint
    var animatableData: CGPoint.AnimatableData {
        get {
            originOffset.animatableData
        }
        set {
            originOffset.animatableData = newValue
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let adjustedX = rect.width * originOffset.x
        let adjustedY = rect.height * originOffset.y
        let smallestDimension = min(rect.width, rect.height)
        path.addArc(center: CGPoint(x: adjustedX, y: adjustedY), radius: smallestDimension / 2, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        return path
    }
}

private enum GradientColors {
    static var all: [Color] {
        [
            Color.red,
            Color.blue,
            Color.yellow,
            Color.red,
        ]
    }

    static var backgroundColor: Color = .black
}

#Preview {
    ContentView()
}
