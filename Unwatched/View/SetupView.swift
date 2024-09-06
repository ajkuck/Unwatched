//
//  SetupView.swift
//  Unwatched
//

import SwiftUI
import BackgroundTasks
import SwiftData
import OSLog

struct SetupView: View {
    @AppStorage(Const.themeColor) var theme: ThemeColor = .teal
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(PlayerManager.self) var player
    @Environment(RefreshManager.self) var refresher
    @Environment(ImageCacheManager.self) var imageCacheManager

    @State var sheetPos = SheetPositionReader.load()
    @State var alerter: Alerter = Alerter()
    @State var navManager = NavigationManager.load()

    let appDelegate: AppDelegate

    var body: some View {
        ContentView()
            .tint(theme.color)
            .environment(sheetPos)
            .environment(alerter)
            .environment(navManager)
            .alert(isPresented: $alerter.isShowingAlert) {
                alerter.alert ?? Alert(title: Text(verbatim: ""))
            }
            .onAppear {
                let container = modelContext.container
                appDelegate.navManager = navManager
                appDelegate.container = container
                refresher.container = container
                refresher.showError = alerter.showError
            }
            .onChange(of: scenePhase) {
                switch scenePhase {
                case .active:
                    player.isInBackground = false
                    NotificationManager.clearNotifications()
                    Logger.log.info("active")
                    Task {
                        refresher.handleAutoBackup(UIDevice.current.name)
                        await refresher.handleBecameActive()
                    }
                case .background:
                    Logger.log.info("background")
                    player.isInBackground = true
                    NotificationManager.clearNotifications()
                    Task {
                        await saveData()
                    }
                    refresher.handleBecameInactive()
                    refresher.scheduleVideoRefresh()
                case .inactive:
                    Logger.log.info("inactive")
                    saveCurrentVideo()
                default:
                    break
                }
            }
    }

    func saveData() async {
        navManager.save()
        sheetPos.save()
        await imageCacheManager.persistCache()
        Logger.log.info("saved state")
    }

    func saveCurrentVideo() {
        let videoId = player.video?.persistentModelID
        let data = try? JSONEncoder().encode(videoId)
        UserDefaults.standard.setValue(data, forKey: Const.nowPlayingVideo)
    }
}

#Preview {
    SetupView(appDelegate: AppDelegate())
        .modelContainer(DataController.previewContainer)
}
