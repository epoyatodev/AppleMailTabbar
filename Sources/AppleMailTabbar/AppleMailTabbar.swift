import SwiftUI


/// Tab Item Protocol
public protocol MailTabItem: CaseIterable, Hashable {
    var symbol: String { get }
    var title: String { get }
    var activeTint: Color { get }
    var activeBackground: Color { get }
}

/// Full screen container: `NavigationStack` + `ScrollView` with the tab bar on top of the content.
public struct AppleMailTabbar<Tab: MailTabItem, Content: View>: View {
    private let listTitle: String
    private let spacing: CGFloat
    private let trailingVisibility: CGFloat
    private let isGestureEnabled: Bool
    @Binding private var selection: Tab
    private let content: (Tab) -> Content

    public init(
        listTitle: String,
        selection: Binding<Tab>,
        spacing: CGFloat = 8,
        trailingVisibility: CGFloat = 15,
        isGestureEnabled: Bool = true,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.listTitle = listTitle
        self._selection = selection
        self.spacing = spacing
        self.trailingVisibility = trailingVisibility
        self.isGestureEnabled = isGestureEnabled
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                MailTabBar(
                    selection: $selection,
                    spacing: spacing,
                    trailingVisibility: trailingVisibility,
                    isGestureEnabled: isGestureEnabled
                )

                /// Content
                content(selection)
            }
            .safeAreaPadding(15)
            .navigationTitle(listTitle)
        }
    }
}

/// Standalone tab bar, without any container. Place it wherever you need it
/// (a `List` row, a `safeAreaInset`, a toolbar, your own `ScrollView`...).
public struct MailTabBar<Tab: MailTabItem>: View {
    private let spacing: CGFloat
    private let trailingVisibility: CGFloat
    private let isGestureEnabled: Bool
    @Binding private var selection: Tab
    /// View Properties
    ///  Used to calculate the inactive tab with to sync animations perfectly!
    @State private var tabTitleSizes: [Tab: CGSize] = [:]
    @State private var previousTab: Tab?

    public init(
        selection: Binding<Tab>,
        spacing: CGFloat = 8,
        trailingVisibility: CGFloat = 15,
        isGestureEnabled: Bool = true
    ) {
        self._selection = selection
        self.spacing = spacing
        self.trailingVisibility = trailingVisibility
        self.isGestureEnabled = isGestureEnabled
    }

    public var body: some View {
        let isLastTabActive: Bool = selection == allTabs.last
        GeometryReader {
            let containerSize = $0.size
            let activeTitleWidth: CGFloat = tabTitleSizes[selection]?.width ?? 0
            /// Symbol: 20, Horizontal Padding: 40, Spacing: 6
            let activeWidth: CGFloat = activeTitleWidth + 60 + 6
            let removeCount: Int = isLastTabActive ? 1 : min(2, allTabs.count - 1)
            /// Avoid division by zero when there is a single tab
            let inactiveCount: Int = max(allTabs.count - removeCount, 1)
            let spacingValue: CGFloat = CGFloat(inactiveCount) * spacing
            let inActiveWidth: CGFloat = max((containerSize.width - activeWidth - spacingValue) / CGFloat(inactiveCount), 0)

            HStack(spacing: spacing) {
                ForEach(allTabs, id: \.self) { tab in
                    TabItemView(tab, inActiveWidth: inActiveWidth)
                }
            }
        }
        .padding(.trailing, isLastTabActive ? 0 : trailingVisibility)
        .frame(height: 38)
        .contentShape(.rect)
        .gesture(toggleGesture, isEnabled: isGestureEnabled)
        .animation(animation, value: selection)
        .onAppear {
            guard previousTab == nil else { return }
            previousTab = selection
        }
        .onChange(of: selection) { oldValue, newValue in
            previousTab = oldValue
        }
    }

    @ViewBuilder
    private func TabItemView(_ tab: Tab, inActiveWidth: CGFloat) -> some View {
        let isActive = selection == tab
        HStack(spacing: isActive ? 6 : 0) {
            Image(systemName: tab.symbol)
                .font(.body)
                .frame(width: 20)
                .zIndex(1)

            Text(tab.title)
                .font(.callout)
                .fontWeight(.semibold)
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    tabTitleSizes[tab] = newValue
                }
                .frame(width: isActive ? nil : 0, alignment: .leading)
                .animation(animation.speed(isActive ? 1 : 2.5)) { content in
                    content
                        .opacity(isActive ? 1 : 0)
                }
        }
        .foregroundStyle(isActive ? tab.activeTint : .gray)
        .padding(.horizontal, isActive ? 20 : 0)
        .frame(maxHeight: .infinity)
        .frame(width: isActive ? nil : inActiveWidth)
        .background {
            ZStack {
                Capsule()
                    .fill(.fill)
                    .opacity(isActive ? 0 : 1)

                Capsule()
                    .fill(tab.activeBackground)
                    .opacity(isActive ? 1 : 0)
            }
        }
        .clipShape(.capsule)
        .contentShape(.capsule)
        .geometryGroup()
        .onTapGesture {
            if let lastTab = allTabs.last, let previousTab, selection == tab {
                if selection == lastTab {
                    selection = previousTab
                } else {
                    selection = lastTab
                }
            } else {
                selection = tab
            }
        }
    }

    /// Toggle Gesture
    private var toggleGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let xTranslation = value.translation.width
                guard abs(xTranslation) > 40 else { return }
                if xTranslation > 0 {
                    guard let previousTab, selection == allTabs.last else { return }
                    selection = previousTab
                } else {
                    guard let lastTab = allTabs.last else { return }
                    selection = lastTab
                }
            }
    }

    private var allTabs: [Tab] {
        Array(Tab.allCases)
    }

    /// Animation
    private var animation: Animation {
        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }
}


#if DEBUG
enum MailTab: MailTabItem {
    case primary
    case transactions
    case updates
    case promotions
    case allMails

    var title: String {
        switch self {
        case .primary: return "Primary"
        case .transactions: return "Transactions"
        case .updates: return "Updates"
        case .promotions: return "Promotions"
        case .allMails: return "All mails"
        }
    }

    var symbol: String {
        switch self {
        case .primary: return "house"
        case .transactions: return "creditcard"
        case .updates: return "exclamationmark.circle"
        case .promotions: return "gift"
        case .allMails: return "envelope"
        }
    }

    var activeBackground: Color {
        switch self {
        case .primary: .blue
        case .transactions: .green
        case .updates: .indigo
        case .promotions: .pink
        case .allMails: Color.white
        }
    }

    var activeTint: Color {
        switch self {
        case .primary, .transactions, .updates, .promotions: .white
        case .allMails:
            Color.black
        }
    }
}

#Preview {
    @Previewable @State var activeTab: MailTab = .primary
    AppleMailTabbar(listTitle: "Inbox", selection: $activeTab) { tab in
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(1...20, id: \.self) { index in
                Text("\(tab.title) mail #\(index)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.fill.tertiary, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.top, 15)
    }
}

#Preview("List") {
    @Previewable @State var activeTab: MailTab = .primary
    NavigationStack {
        List {
            MailTabBar(selection: $activeTab)
                .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            ForEach(1...20, id: \.self) { index in
                Text("\(activeTab.title) mail #\(index)")
            }
        }
        .listStyle(.plain)
        .navigationTitle("Inbox")
    }
}
#endif
