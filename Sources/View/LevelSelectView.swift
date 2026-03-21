import SwiftUI

struct LevelSelectView: View {
    let onSelectLevel: (Int) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            scrollContent
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Damaze")
                .font(.largeTitle.bold())

            if let nextIndex = LevelProgress.nextUnsolvedIndex() {
                Button {
                    onSelectLevel(nextIndex)
                } label: {
                    Label("Continue Level \(nextIndex + 1)", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: 260)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            } else {
                Text("All levels complete!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(LevelStore.allLevels.enumerated()), id: \.offset) { index, levelData in
                    LevelCell(
                        index: index,
                        levelData: levelData,
                        isCompleted: LevelProgress.isCompleted(levelIndex: index),
                        bestMoves: LevelProgress.bestMoves(levelIndex: index)
                    ) {
                        onSelectLevel(index)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

private struct LevelCell: View {
    let index: Int
    let levelData: LevelData
    let isCompleted: Bool
    let bestMoves: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted
                            ? levelData.colorScheme.color.opacity(0.2)
                            : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isCompleted ? levelData.colorScheme.color : Color(.separator),
                                    lineWidth: isCompleted ? 2 : 1
                                )
                        )

                    VStack(spacing: 2) {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(levelData.colorScheme.color)
                        }

                        Text("\(index + 1)")
                            .font(.title3.bold())
                            .foregroundStyle(isCompleted ? levelData.colorScheme.color : .primary)
                    }
                }
                .frame(height: 72)

                Text(levelData.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let best = bestMoves {
                    Text("\(best) moves")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
