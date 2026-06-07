import SwiftUI

struct NotificationInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = NotificationStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if store.notifications.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xxl * 2)
                } else {
                    StyledCard {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(store.notifications.enumerated()), id: \.element.id) { index, item in
                                Button {
                                    store.markRead(item.id)
                                } label: {
                                    InboxRow(item: item)
                                }
                                .buttonStyle(.plain)

                                if index < store.notifications.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Meldingen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                }
                .accessibilityLabel("Terug")
            }

            if store.unreadCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Alles gelezen") {
                        store.markAllRead()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.Colors.textDim)
            Text("Geen meldingen")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            Text("Meldingen over je stappendoel verschijnen hier.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
        }
    }
}

// MARK: - Row

private struct InboxRow: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(item.isRead ? Theme.Colors.surface2 : Theme.Colors.accent.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.isRead ? Theme.Colors.textDim : Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(item.title)
                    .font(.system(size: 15, weight: item.isRead ? .regular : .semibold))
                    .foregroundColor(item.isRead ? Theme.Colors.textMuted : Theme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.body)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
                    .multilineTextAlignment(.leading)

                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textDim)
                    .padding(.top, 2)
            }

            if !item.isRead {
                Circle()
                    .fill(Theme.Colors.tomato)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}
