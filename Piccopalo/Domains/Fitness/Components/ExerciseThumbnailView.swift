import SwiftUI

struct ExerciseThumbnailView: View {
    let exercise: Exercise
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url = exercise.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        categoryFallback
                    case .empty:
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.Colors.surface2)
                    @unknown default:
                        categoryFallback
                    }
                }
            } else {
                categoryFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var categoryFallback: some View {
        Image(systemName: exercise.category.icon)
            .font(.system(size: size * 0.4))
            .foregroundColor(Theme.Colors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.surface2)
    }
}
