import AppKit
import UniformTypeIdentifiers

/// Wraps `NSOpenPanel`, replacing `Microsoft.Win32.OpenFileDialog` usage in the original windows.
class FilePicker {
    @MainActor
    static func selectFile(extensions: [String]) -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
