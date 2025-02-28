//
//  PlayerControls.swift
//  Unwatched
//

import SwiftUI
import UnwatchedShared

struct PlayerControls: View {
    @AppStorage(Const.playVideoFullscreen) var playVideoFullscreen: Bool = false
    @AppStorage(Const.fullscreenControlsSetting) var fullscreenControlsSetting: FullscreenControls = .autoHide
    @AppStorage(Const.hideControlsFullscreen) var hideControlsFullscreen = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(PlayerManager.self) var player
    @Environment(SheetPositionReader.self) var sheetPos
    @Environment(NavigationManager.self) var navManager
    @Environment(RefreshManager.self) var refresher

    @State var browserUrl: BrowserUrl?

    @ScaledMetric var speedSpacing = 10

    let compactSize: Bool
    let showInfo: Bool
    let horizontalLayout: Bool
    let enableHideControls: Bool

    let setShowMenu: () -> Void
    let markVideoWatched: (_ showMenu: Bool, _ source: VideoSource) -> Void
    var sleepTimerVM: SleepTimerViewModel

    @State var autoHideVM = AutoHideVM()

    var body: some View {
        let compactHeight = player.videoAspectRatio <= Const.consideredTallAspectRatio

        let layout = compactSize
            ? AnyLayout(HStackLayout(spacing: 25))
            : AnyLayout(VStackLayout(spacing: compactHeight ? 15 : 25))

        let outerLayout = horizontalLayout
            ? AnyLayout(HStackLayout(spacing: 10))
            : AnyLayout(VStackLayout(spacing: compactHeight ? 7 : 10))

        ZStack {
            outerLayout {
                if !player.embeddingDisabled && !compactSize {
                    Spacer()
                }

                if showInfo {
                    DescriptionMiniProgressBar()
                        .padding(.vertical, 10)
                }

                ChapterMiniControlView(setShowMenu: setShowMenu)
                    .padding(.horizontal)

                if !player.embeddingDisabled && !compactSize && !compactHeight {
                    Spacer()
                    Spacer()
                }

                layout {
                    if compactSize {
                        SleepTimer(viewModel: sleepTimerVM, onEnded: onSleepTimerEnded)
                    }

                    HStack(spacing: speedSpacing) {
                        CombinedPlaybackSpeedSetting(
                            spacing: speedSpacing,
                            showTemporarySpeed: compactSize
                        )
                        if fullscreenControlsSetting != .disabled && !UIDevice.requiresFullscreenWebWorkaround {
                            RotateOrientationButton()
                        }

                        if !UIDevice.isMac {
                            PipButton()
                        }
                    }
                    .environment(\.symbolVariants, .fill)

                    HStack {
                        WatchedButton(markVideoWatched: markVideoWatched)
                            .frame(maxWidth: .infinity)

                        PlayButton(size:
                                    (player.embeddingDisabled || compactSize)
                                    ? 70
                                    : 90
                        )
                        .fontWeight(.black)

                        NextVideoButton(markVideoWatched: markVideoWatched)
                            .frame(maxWidth: .infinity)

                        if enableHideControls {
                            HideControlsButton()
                        }
                    }
                    .padding(.horizontal, 10)

                    if compactHeight {
                        // make sure play button vertical spacing is equal
                        Spacer()
                            .frame(height: 0)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 1000)

                if !player.embeddingDisabled && !compactSize && !compactHeight {
                    Spacer()
                    Spacer()
                }
                if !compactSize {
                    VideoPlayerFooter(openBrowserUrl: openBrowserUrl,
                                      setShowMenu: setShowMenu,
                                      sleepTimerVM: sleepTimerVM,
                                      onSleepTimerEnded: onSleepTimerEnded)
                }
            }
            .opacity(showControls ? 1 : 0)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onSizeChange { size in
            sheetPos.setPlayerControlHeight(size.height - Const.playerControlPadding)
        }
        .sheet(item: $browserUrl) { browserUrl in
            BrowserView(refresher: refresher,
                        startUrl: browserUrl)
                .environment(\.colorScheme, colorScheme)
        }
        .animation(.default.speed(3), value: showControls)
        .animation(.default, value: compactHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if !showControls {
                autoHideVM.setShowControls()
            }
        }
        .onHover { over in
            autoHideVM.setKeepVisible(over, "hover")
        }
    }

    func onSleepTimerEnded(_ fadeOutSeconds: Double?) {
        var seconds = player.currentTime ?? 0
        player.pause()
        if let fadeOutSeconds = fadeOutSeconds, fadeOutSeconds > seconds {
            seconds -= fadeOutSeconds
        }
        player.updateElapsedTime(seconds)
    }

    func openBrowserUrl(_ url: BrowserUrl) {
        let browserAsTab = UserDefaults.standard.bool(forKey: Const.browserAsTab)
        if browserAsTab {
            sheetPos.setDetentMiniPlayer()
            navManager.openUrlInApp(url)
        } else {
            browserUrl = url
        }
    }

    var showControls: Bool {
        !hideControlsFullscreen
            || fullscreenControlsSetting != .autoHide
            || fullscreenControlsSetting == .autoHide && (!player.isPlaying || autoHideVM.showControls)
            || player.videoIsCloseToEnd
    }
}

#Preview {
    PlayerControls(compactSize: false,
                   showInfo: false,
                   horizontalLayout: false,
                   enableHideControls: false,
                   setShowMenu: { },
                   markVideoWatched: { _, _ in },
                   sleepTimerVM: SleepTimerViewModel())
        .modelContainer(DataProvider.previewContainer)
        .environment(NavigationManager.getDummy())
        .environment(PlayerManager.getDummy())
        .environment(SheetPositionReader())
        .environment(RefreshManager())
        .tint(Color.neutralAccentColor)
}
