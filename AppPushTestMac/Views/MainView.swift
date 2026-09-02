import SwiftUI
import AppKit

/// Ports `MainWindow`: two buttons that open the Android FCM and iOS APNs tools.
struct MainView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            Text("AppPushTestForm")
                .font(.title2)
                .padding(.top, 24)

            Button("Android FCM") { openWindow(id: "androidFCM") }
                .frame(width: 160)

            Button("iOS APNs") { openWindow(id: "iosAPNs") }
                .frame(width: 160)

            Spacer()
        }
        .frame(width: 384, height: 176)
        .background(_WindowCenteringView())
    }
}

/// Grabs the hosting NSWindow and calls center() so the window always opens at screen center.
private struct _WindowCenteringView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { view.window?.center() }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
