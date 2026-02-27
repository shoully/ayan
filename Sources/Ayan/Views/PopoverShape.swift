import SwiftUI

struct PopoverShape: Shape {
    var nubSize: CGFloat = 12
    var cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let nubHalfWidth = nubSize / 2
        
        // The main content rect, leaving space at the top for the nub
        let contentRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - nubSize)

        // Start at top-left corner
        path.move(to: CGPoint(x: contentRect.minX, y: contentRect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: contentRect.minX + cornerRadius, y: contentRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // Top edge leading to the nub
        path.addLine(to: CGPoint(x: rect.midX - nubHalfWidth, y: contentRect.maxY))
        
        // The nub itself
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)) // Tip of the nub
        path.addLine(to: CGPoint(x: rect.midX + nubHalfWidth, y: contentRect.maxY))
        
        // Top edge after the nub
        path.addLine(to: CGPoint(x: contentRect.maxX - cornerRadius, y: contentRect.maxY))
        
        // Top-right corner
        path.addArc(
            center: CGPoint(x: contentRect.maxX - cornerRadius, y: contentRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: contentRect.maxX, y: contentRect.minY + cornerRadius))
        
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: contentRect.maxX - cornerRadius, y: contentRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(-90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: contentRect.minX + cornerRadius, y: contentRect.minY))
        
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: contentRect.minX + cornerRadius, y: contentRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-180),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}
