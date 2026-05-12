import Foundation
import Combine

struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let body: String
    let date: Date
    var isRead: Bool

    init(id: UUID = UUID(), title: String, body: String, date: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.isRead = isRead
    }
}

final class NotificationStore: ObservableObject {
    static let shared = NotificationStore()

    @Published private(set) var notifications: [NotificationItem] = []

    private let key = "piccopalo_notification_inbox"

    private init() {
        load()
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func add(title: String, body: String) {
        let item = NotificationItem(title: title, body: body)
        notifications.insert(item, at: 0)
        persist()
    }

    func markRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
        persist()
    }

    func markAllRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) else { return }
        notifications = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notifications) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
