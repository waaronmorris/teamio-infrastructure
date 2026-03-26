import SwiftUI

struct AppLogo: View {
    var size: CGFloat = 40

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22)
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "trophy.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    HStack(spacing: 8) {
        AppLogo(size: 32)
        Text("TeamIO")
            .font(.title2.bold())
    }
}
