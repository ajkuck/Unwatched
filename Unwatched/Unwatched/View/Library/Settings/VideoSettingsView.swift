//
//  VideoSettingsView.swift
//  Unwatched
//

import SwiftUI
import UnwatchedShared

struct VideoSettingsView: View {
    @AppStorage(Const.defaultVideoPlacement) var defaultVideoPlacement: VideoPlacement = .inbox
    @AppStorage(Const.hideShorts) var hideShorts: Bool = false
    @AppStorage(Const.requireClearConfirmation) var requireClearConfirmation: Bool = true
    @AppStorage(Const.showClearQueueButton) var showClearQueueButton: Bool = true
    @AppStorage(Const.showAddToQueueButton) var showAddToQueueButton: Bool = false
    @AppStorage(Const.autoRefresh) var autoRefresh: Bool = true
    @AppStorage(Const.enableQueueContextMenu) var enableQueueContextMenu: Bool = false

    var body: some View {
        ZStack {
            Color.backgroundColor.ignoresSafeArea(.all)

            MyForm {
                MySection {
                    Picker("newVideos", selection: $defaultVideoPlacement) {
                        ForEach(VideoPlacement.allCases.filter { $0 != .defaultPlacement }, id: \.self) {
                            Text($0.description(defaultPlacement: ""))
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle(isOn: $autoRefresh) {
                        Text("autoRefresh")
                    }
                }

                MySection("videoTriage") {
                    Toggle(isOn: $requireClearConfirmation) {
                        Text("requireClearConfirmation")
                    }
                    Toggle(isOn: $showAddToQueueButton) {
                        Text("showAddToQueueButton")
                    }
                }

                MySection("queue") {
                    Toggle(isOn: $showClearQueueButton) {
                        Text("showClearQueueButton")
                    }
                    Toggle(isOn: $enableQueueContextMenu) {
                        Text("enableQueueContextMenu")
                    }
                }

                MySection("shortsSettings") {
                    Toggle(isOn: $hideShorts) {
                        Text("hideShortsEverywhere")
                    }
                }

                SponsorBlockSettingsView()
            }
            .myNavigationTitle("videoSettings")
        }
    }
}

#Preview {
    VideoSettingsView()
}
