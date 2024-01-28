//
//  NavigationManager.swift
//  Unwatched
//

import Foundation
import SwiftUI
import SwiftData

@Observable class NavigationManager: Codable {
    var showMenu = true
    var tab = Tab.queue

    var presentedSubscriptionQueue = [Subscription]()
    var presentedSubscriptionInbox = [Subscription]()
    var presentedLibrary = NavigationPath()

    @ObservationIgnored var topListItemId: String?
    @ObservationIgnored private var lastTabTwiceDate: Date?
    @ObservationIgnored private var lastLibrarySubscriptionId: Subscription?

    init() { }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NavManagerCodingKeys.self)

        showMenu = try container.decode(Bool.self, forKey: .showMenu)
        tab = try container.decode(Tab.self, forKey: .tab)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NavManagerCodingKeys.self)

        try container.encode(showMenu, forKey: .showMenu)
        try container.encode(tab, forKey: .tab)
    }

    func pushSubscription(_ subscription: Subscription) {
        switch tab {
        case .inbox:
            if presentedSubscriptionInbox.last != subscription {
                presentedSubscriptionInbox.append(subscription)
            }
        case .queue:
            if presentedSubscriptionQueue.last != subscription {
                presentedSubscriptionQueue.append(subscription)
            }
        case .library:
            if lastLibrarySubscriptionId != subscription {
                presentedLibrary.append(subscription)
                lastLibrarySubscriptionId = subscription
            }
        }
    }

    func setScrollId(_ value: String?, _ differentiator: String = "") {
        topListItemId = NavigationManager.getScrollId(value, differentiator)
    }

    static func getScrollId(_ value: String?, _ differentiator: String = "") -> String {
        "scrollId-\(differentiator)-\(value ?? "")"
    }

    func handleTappedTwice() -> Bool {
        var isOnTopView = false
        switch tab {
        case .inbox:
            isOnTopView = presentedSubscriptionInbox.isEmpty
        case .queue:
            isOnTopView = presentedSubscriptionQueue.isEmpty
        case .library:
            isOnTopView = presentedLibrary.isEmpty
        }

        if !isOnTopView {
            popCurrentNaviagtionStack()
        }
        return isOnTopView
    }

    func popCurrentNaviagtionStack() {
        switch tab {
        case .inbox:
            _ = presentedSubscriptionInbox.popLast()
        case .queue:
            _ = presentedSubscriptionQueue.popLast()
        case .library:
            if !presentedLibrary.isEmpty {
                presentedLibrary.removeLast()
            }
        }
    }

    static func getDummy() -> NavigationManager {
        let navManager = NavigationManager()
        return navManager
    }
}

enum NavManagerCodingKeys: CodingKey {
    case showMenu
    case tab
}

enum Tab: Codable {
    case inbox
    case queue
    case library
}
