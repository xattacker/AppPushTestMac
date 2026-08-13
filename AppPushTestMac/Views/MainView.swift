import SwiftUI

/// Ports `MainWindow`: two buttons that open the Android FCM and iOS APNS tools.
struct MainView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            Text("AppPushTestForm")
                .font(.title2)
                .padding(.top, 24)

            Button("Android FCM") { openWindow(id: "androidFCM") }
                .frame(width: 160)

            Button("iOS APNS") { openWindow(id: "iosAPNS") }
                .frame(width: 160)

            Spacer()
        }
        .frame(width: 384, height: 176)
    }
}
