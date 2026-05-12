import SwiftUI

struct NotificationInboxView: View {
    @ObservedObject private var store = NotificationStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if store.notifications.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, DesignTokens.Spacing.xxl * 2)
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
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Meldingen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.unreadCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Alles gelezen") {
                        store.markAllRead()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.accent)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(DesignTokens.Colors.textDim)
            Text("Geen meldingen")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.text)
            Text("Meldingen over je stappendoel verschijnen hier.")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xxl)
        }
    }
}

// MARK: - Row

private struct InboxRow: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(item.isRead ? DesignTokens.Colors.surface2 : DesignTokens.Colors.accent.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.isRead ? DesignTokens.Colors.textDim : DesignTokens.Colors.accent)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(item.title)
                    .font(.system(size: 15, weight: item.isRead ? .regular : .semibold))
                    .foregroundColor(item.isRead ? DesignTokens.Colors.textMuted : DesignTokens.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.body)
                    .font(.system(size: 13))
                    .foregroundColor(DesignTokens.Colors.textMuted)
                    .multilineTextAlignment(.leading)

                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.Colors.textDim)
                    .padding(.top, 2)
            }

            if !item.isRead {
                Circle()
                    .fill(DesignTokens.Colors.tomato)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}
