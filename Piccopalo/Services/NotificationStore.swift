import Foundation
import Combine

struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let sourceIdentifier: String?
    let title: String
    let body: String
    let date: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        sourceIdentifier: String? = nil,
        title: String,
        body: String,
        date: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.sourceIdentifier = sourceIdentifier
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
        addOrUpdate(identifier: nil, title: title, body: body)
    }

    func addOrUpdate(identifier: String?, title: String, body: String, date: Date = Date(), isRead: Bool = false) {
        if let identifier,
           let index = notifications.firstIndex(where: { $0.sourceIdentifier == identifier }) {
            let existing = notifications.remove(at: index)
            notifications.insert(
                NotificationItem(
                    id: existing.id,
                    sourceIdentifier: identifier,
                    title: title,
                    body: body,
                    date: date,
                    isRead: existing.isRead || isRead
                ),
                at: 0
            )
        } else {
            notifications.insert(
                NotificationItem(
                    sourceIdentifier: identifier,
                    title: title,
                    body: body,
                    date: date,
                    isRead: isRead
                ),
                at: 0
            )
        }
        persist()
    }

    func markRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
        persist()
    }

    func markReadBySourceIdentifier(_ identifier: String) {
        guard let index = notifications.firstIndex(where: { $0.sourceIdentifier == identifier }) else { return }
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
