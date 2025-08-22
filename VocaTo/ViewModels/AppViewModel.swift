import Foundation
import CoreData

final class AppViewModel: ObservableObject {
    let persistence: PersistenceController
    @Published var studyAutoAdvanceSpeed: Double // seconds per card when auto-advance enabled
    @Published var notificationsEnabled: Bool
    @Published var notificationHour: Int
    @Published var notificationMinute: Int

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let defaults = UserDefaults.standard
        let speed = defaults.double(forKey: "studyAutoAdvanceSpeed")
        self.studyAutoAdvanceSpeed = speed == 0 ? 2.0 : speed
        self.notificationHour = defaults.integer(forKey: "notificationHour") == 0 ? 20 : defaults.integer(forKey: "notificationHour")
        self.notificationMinute = defaults.integer(forKey: "notificationMinute")
        self.notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")

        if notificationsEnabled {
            NotificationService.shared.requestAuthorization { _ in }
            NotificationService.shared.scheduleDaily(hour: notificationHour, minute: notificationMinute)
        }
    }

    func saveContext() { persistence.save() }

    func updateAutoAdvanceSpeed(_ seconds: Double) {
        studyAutoAdvanceSpeed = seconds
        UserDefaults.standard.set(seconds, forKey: "studyAutoAdvanceSpeed")
    }

    func setNotifications(enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        if enabled {
            NotificationService.shared.requestAuthorization { granted in
                if granted {
                    NotificationService.shared.scheduleDaily(hour: self.notificationHour, minute: self.notificationMinute)
                }
            }
        } else {
            NotificationService.shared.cancelAll()
        }
    }

    func updateNotificationTime(hour: Int, minute: Int) {
        notificationHour = hour
        notificationMinute = minute
        UserDefaults.standard.set(hour, forKey: "notificationHour")
        UserDefaults.standard.set(minute, forKey: "notificationMinute")
        if notificationsEnabled {
            NotificationService.shared.scheduleDaily(hour: hour, minute: minute)
        }
    }
}

