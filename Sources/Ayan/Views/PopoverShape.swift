import SwiftUI

struct PopoverShape: Shape {
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}
