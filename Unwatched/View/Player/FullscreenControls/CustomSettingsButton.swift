//
//  CustomSettingsButton.swift
//  Unwatched
//

import SwiftUI

struct CustomSettingsButton: View {
    @Binding var playbackSpeed: Double
    @Bindable var player: PlayerManager

    @State var hapticToggle: Bool = false

    var body: some View {
        Toggle(isOn: Binding(get: {
            player.video?.subscription?.customSpeedSetting != nil
        }, set: { value in
            player.video?.subscription?.customSpeedSetting = value ? playbackSpeed : nil
            hapticToggle.toggle()
        })) {
            Image(systemName: "lock")
        }
        .help("customSpeedSetting")
        .padding(2)
        .toggleStyle(OutlineToggleStyle(isSmall: true))
        .disabled(player.video?.subscription == nil)
        .sensoryFeedback(Const.sensoryFeedback, trigger: hapticToggle)
    }
}
