import SwiftUI

struct NudgeView: View {
    let projectName: String
    let color: Color
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("Working on ")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(projectName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            Divider().frame(height: 12)
            
            Button(action: onConfirm) {
                Text("Confirm")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.2))
            .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
