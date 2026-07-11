import SwiftUI
import UIKit

// Confetti burst overlay. Increment `trigger` to fire a new burst.
struct ConfettiView: UIViewRepresentable {
    var trigger: Int
    var intensity: CGFloat = 1.0

    func makeUIView(context: Context) -> ConfettiUIView { ConfettiUIView() }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
        guard trigger != context.coordinator.lastTrigger else { return }
        context.coordinator.lastTrigger = trigger
        uiView.burst(intensity: intensity)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var lastTrigger = 0 }
}

final class ConfettiUIView: UIView {
    override var isOpaque: Bool { get { false } set {} }
    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { super.init(coder: coder); backgroundColor = .clear }

    private var pendingBurst: CGFloat?

    override func layoutSubviews() {
        super.layoutSubviews()
        if let intensity = pendingBurst, bounds.width > 0 {
            pendingBurst = nil
            fireBurst(intensity: intensity)
        }
    }

    func burst(intensity: CGFloat = 1.0) {
        guard bounds.width > 0 else {
            pendingBurst = intensity
            return
        }
        fireBurst(intensity: intensity)
    }

    private func fireBurst(intensity: CGFloat) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: bounds.width * 1.1, height: 1)
        emitter.emitterCells = makeCells(intensity: intensity)
        layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                emitter.removeFromSuperlayer()
            }
        }
    }

    private func makeCells(intensity: CGFloat) -> [CAEmitterCell] {
        let colors: [UIColor] = [
            .systemPink, .systemYellow, .systemBlue,
            .systemGreen, .systemOrange, .systemPurple, .white
        ]
        return colors.flatMap { color -> [CAEmitterCell] in
            [makeCell(color: color, shape: .rect, intensity: intensity),
             makeCell(color: color, shape: .circle, intensity: intensity)]
        }
    }

    private enum Shape { case rect, circle }

    private func makeCell(color: UIColor, shape: Shape, intensity: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = Float(8 * intensity)
        cell.lifetime = 5.0
        cell.lifetimeRange = 2.0
        cell.velocity = 300 * intensity
        cell.velocityRange = 120
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = .pi / 5
        cell.spin = 3
        cell.spinRange = 6
        cell.scale = 0.45
        cell.scaleRange = 0.25
        cell.color = color.cgColor
        cell.contents = shapeImage(shape)?.cgImage
        return cell
    }

    private func shapeImage(_ shape: Shape) -> UIImage? {
        let size = CGSize(width: 12, height: 8)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            switch shape {
            case .rect:
                ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            case .circle:
                ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
            }
        }
    }
}
