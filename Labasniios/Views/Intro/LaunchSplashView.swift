import SwiftUI

struct LaunchSplashView: View {
    @State private var animateLogo = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.e8aabe, .a7e0e0], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("logocercle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
                    .scaleEffect(animateLogo ? 1 : 0.85)
                    .opacity(animateLogo ? 1 : 0.6)
                    .animation(.easeOut(duration: 0.8), value: animateLogo)

                Text("Labasni")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                Text("Votre styliste intelligent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .onAppear {
            animateLogo = true
        }
    }
}

#Preview {
    LaunchSplashView()
}
