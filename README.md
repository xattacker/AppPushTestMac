# AppPushTestMac

A native SwiftUI (Swift 6, macOS 14+) port of [`AppPushTestForm`](../AppPushTestForm-master) —
a small internal tool for manually sending test push notifications via Android FCM and iOS APNS.

This is a full rewrite, not a wrapper: it keeps the same three windows and the same fields, but
every piece of networking, crypto, and persistence is reimplemented with native Apple frameworks
(`URLSession`, `CryptoKit`, `Security`) instead of the .NET/PushSharp/Jose-JWT stack the original
used.

## Project structure

Generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` — open
`AppPushTestMac.xcodeproj` in Xcode to build and run (⌘R). If you edit `project.yml` (add a
target, change entitlements, etc.), re-run `xcodegen generate` to regenerate the `.xcodeproj`.

```
AppPushTestMac/
  AppPushTestMacApp.swift      — app entry point, declares the 3 windows
  Models/                      — Codable records (mirrors AppPush.Data.* classes)
  Services/                    — networking, JWT signing, persistence, file picking
  Views/                       — MainView, AndroidFCMView, IOSAPNSView, token list/editor
  Assets.xcassets, entitlements
```

## Windows → screens

| Original (WPF)        | Ported (SwiftUI)     |
|------------------------|-----------------------|
| `MainWindow`            | `MainView` — opens the two tool windows |
| `AndroidFCMWindow`      | `AndroidFCMView` |
| `IOS_APNSWindow`        | `IOSAPNSView` (segmented control instead of tabs) |
| `DeviceTokenEditWindow` | `DeviceTokenEditView` (sheet), shared by both tools via `DeviceTokenListView` |

## Behavior differences from the original

- **Multiple device tokens are actually all used.** The original `ApnsTBASender`/`PushSender`
  code only ever sent to `deviceTokens[0]`, even though the UI lets you add several tokens. The
  Mac port sends to every token in the list and reports one result line per token — this seemed
  like an oversight worth fixing rather than faithfully reproducing, since the token list UI only
  makes sense if it's used.
- **Records are stored in `~/Library/Application Support/AppPushTestMac/`** (`fcm_record.json`,
  `apns_record.json`), not next to the executable — the original used a WinForms-style "next to
  the .exe" path, which has no equivalent under App Sandbox on macOS.
- **APNs certificate (.p12) push no longer needs PushSharp.** The original used the PushSharp
  library speaking a legacy binary APNs protocol. This port imports the `.p12` into a
  `SecIdentity` via `Security.framework` (`SecPKCS12Import`) and uses it for mutual-TLS client
  authentication against Apple's modern HTTP/2 provider API
  (`https://api(.development).push.apple.com/3/device/{token}`) — the same endpoint the token-based
  (.p8) sender uses, just authenticated with a client certificate instead of a JWT bearer token.
- **APNs auth key (.p8) JWT signing uses CryptoKit** (`P256.Signing.PrivateKey`) instead of
  `CngKey` + `Jose.JWT`. CryptoKit's ECDSA signature is already in the raw `r‖s` format JWS
  expects, so no ASN.1 handling is needed.

## Known caveat: legacy FCM endpoint

`FCMSender` intentionally still targets `https://fcm.googleapis.com/fcm/send` with a plain
server-key `Authorization: key=...` header, exactly like the original C# code — Google
deprecated this legacy HTTP API in June 2024. If your FCM project's legacy key no longer works,
you'll need to switch to the **FCM v1 HTTP API**
(`POST https://fcm.googleapis.com/v1/projects/{project-id}/messages:send`), which requires an
OAuth2 access token from a service account instead of a static server key — a bigger change
that was out of scope for a straight port and would need its own design (server-side token
minting, most likely, since embedding service-account private keys in a client app is not
advisable).

## App Sandbox

The app ships sandboxed with two entitlements:
- `com.apple.security.network.client` — for the HTTPS calls to FCM/APNs.
- `com.apple.security.files.user-selected.read-only` — so the `.p12`/`.p8` files picked via the
  "Select" buttons (`NSOpenPanel`) can be read.

## Requirements

- Xcode 16+ (uses the modern synchronized-group `.xcodeproj` format)
- macOS 14 Sonoma or later, both to build and to run
