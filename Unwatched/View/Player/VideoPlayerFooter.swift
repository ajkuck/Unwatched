//
//  VideoPlayerFooter.swift
//  Unwatched
//

import SwiftUI

struct VideoPlayerFooter: View {
    @Environment(NavigationManager.self) var navManager
    @Environment(\.modelContext) var modelContext
    @Environment(PlayerManager.self) var player
    @State var hapticToggle: Bool = false
    @Binding var openBrowserUrl: BrowserUrl?

    var setShowMenu: (() -> Void)?
    var sleepTimerVM: SleepTimerViewModel
    var onSleepTimerEnded: (Double?) -> Void

    var body: some View {
        HStack {
            if let video = player.video {
                SleepTimer(viewModel: sleepTimerVM, onEnded: onSleepTimerEnded)
                    .frame(maxWidth: .infinity)

                Button(action: toggleBookmark) {
                    Image(systemName: video.bookmarkedDate != nil
                            ? "bookmark.fill"
                            : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(maxWidth: .infinity)
            }

            if let setShowMenu = setShowMenu {
                Button {
                    setShowMenu()
                } label: {
                    VStack {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 30))
                        Text("showMenu")
                            .font(.caption)
                            .textCase(.uppercase)
                            .padding(.bottom, 3)
                            .fixedSize()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let video = player.video {
                if let url = video.url {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        openBrowserUrl = .url(url.absoluteString)
                    } label: {
                        Image(systemName: "globe.desk")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .font(.system(size: 20))
        .sensoryFeedback(Const.sensoryFeedback, trigger: hapticToggle)
    }

    func toggleBookmark() {
        if let video = player.video {
            VideoService.toggleBookmark(video, modelContext)
            hapticToggle.toggle()
        }
    }
}

#Preview {
    VideoPlayerFooter(
        openBrowserUrl: .constant(.url("asdf")),
        sleepTimerVM: SleepTimerViewModel(),
        onSleepTimerEnded: { _ in })
}
