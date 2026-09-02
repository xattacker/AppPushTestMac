import SwiftUI

@main
struct AppPushTestMacApp: App {
    var body: some Scene {
        WindowGroup("AppPushTestForm", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Android FCM", id: "androidFCM") {
            AndroidFCMView()
        }
        .windowResizability(.contentSize)

        Window("iOS APNs", id: "iosAPNs") {
            IOSAPNsView()
        }
        .windowResizability(.contentSize)
    }
}
