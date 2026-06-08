import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if let url = exercise.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure, .empty:
                            ExerciseThumbnailView(exercise: exercise, size: 220)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                }

                StyledCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(exercise.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.Colors.text)

                        HStack(spacing: Theme.Spacing.md) {
                            Label(exercise.category.label, systemImage: exercise.category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textMuted)

                            if !exercise.difficultyLabel.isEmpty {
                                Text(exercise.difficultyLabel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.green)
                                    .padding(.horizontal, Theme.Spacing.sm)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.green.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let instructions = exercise.instructions, !instructions.isEmpty {
                    StyledCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            SectionLabel("Uitvoering", icon: "list.number")
                            Text(instructions)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.Colors.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
