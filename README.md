# AppleMailTabbar

A SwiftUI tab bar inspired by the category tabs in Apple's Mail app. The active tab expands into a capsule with its icon and title, the others collapse into compact pills, and the last tab acts as an "All mail" toggle.

## Requirements

- iOS 18+
- Swift 6.2+ (Xcode 26+)

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/epoyatodev/AppleMailTabbar.git`
3. Choose a version rule (e.g. *Up to Next Major Version* from `1.0.0`) and add the `AppleMailTabbar` product to your app target.

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/epoyatodev/AppleMailTabbar.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["AppleMailTabbar"])
]
```

## Usage

### 1. Define your tabs

Create an `enum` conforming to `MailTabItem`. **The last case is the special "All mail" tab.**

```swift
import SwiftUI
import AppleMailTabbar

enum InboxTab: MailTabItem {
    case primary, social, promotions, all

    var title: String {
        switch self {
        case .primary: "Primary"
        case .social: "Social"
        case .promotions: "Promotions"
        case .all: "All mail"
        }
    }

    /// SF Symbol name
    var symbol: String {
        switch self {
        case .primary: "person"
        case .social: "bubble.left.and.bubble.right"
        case .promotions: "tag"
        case .all: "tray"
        }
    }

    /// Background of the active capsule
    var activeBackground: Color {
        switch self {
        case .primary: .blue
        case .social: .green
        case .promotions: .pink
        case .all: .white
        }
    }

    /// Icon and title color of the active capsule
    var activeTint: Color {
        self == .all ? .black : .white
    }
}
```

### 2. Add the view

```swift
struct InboxView: View {
    @State private var selectedTab: InboxTab = .primary

    var body: some View {
        AppleMailTabbar(listTitle: "Inbox", selection: $selectedTab) { tab in
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(mails(for: tab)) { mail in
                    MailRow(mail: mail)
                }
            }
            .padding(.top, 15)
        }
    }
}
```

The content closure receives the selected tab. `AppleMailTabbar` already provides its own `NavigationStack`, `ScrollView` and navigation title, so don't wrap it in another `NavigationStack`.

### Options

```swift
AppleMailTabbar(
    listTitle: "Inbox",
    selection: $selectedTab,
    spacing: 8,               // space between capsules
    trailingVisibility: 15,   // how much the last tab peeks from the trailing edge
    isGestureEnabled: true    // enable swipe to toggle
) { tab in
    // content
}
```

### Tab bar only

If you need a different container (e.g. a `List`), use `MailTabBar`. It is just the bar, with no `NavigationStack`, `ScrollView` or title, so you place it wherever you want.

```swift
struct InboxView: View {
    @State private var selectedTab: InboxTab = .primary

    var body: some View {
        NavigationStack {
            List {
                MailTabBar(selection: $selectedTab)
                    .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(mails(for: selectedTab)) { mail in
                    MailRow(mail: mail)
                }
            }
            .navigationTitle("Inbox")
        }
    }
}
```

`MailTabBar` accepts the same `spacing`, `trailingVisibility` and `isGestureEnabled` options.

## Behavior

- **Tap** an inactive tab to select it.
- **Tap the active tab** to jump to the last tab, or back to the previous tab if the last one is active.
- **Swipe left** on the bar to go to the last tab.
- **Swipe right** while on the last tab to return to the previous one.

## License

AppleMailTabbar is available under the MIT license. See [LICENSE](LICENSE).
