import SwiftUI

@main
struct AppPushTestMacApp: App {
    var body: some Scene {
        WindowGroup("AppPushTestForm", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        Window("Android FCM", id: "androidFCM") {
            AndroidFCMView()
        }
        .windowResizability(.contentSize)

        Window("iOS APNS", id: "iosAPNS") {
            IOSAPNSView()
        }
        .windowResizability(.contentSize)
    }
}
