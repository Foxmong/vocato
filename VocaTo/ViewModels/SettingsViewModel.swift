import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var hour: Int
    @Published var minute: Int
    @Published var autoAdvanceSpeed: Double

    init(appViewModel: AppViewModel) {
        self.notificationsEnabled = appViewModel.notificationsEnabled
        self.hour = appViewModel.notificationHour
        self.minute = appViewModel.notificationMinute
        self.autoAdvanceSpeed = appViewModel.studyAutoAdvanceSpeed
    }
}

