import SwiftUI

enum FitnessRoute: Hashable {
    case templates
    case exerciseLibrary
    case template(WorkoutTemplate)
    case session
    case summary
}

struct FitnessHomeView: View {
    @EnvironmentObject var fitnessViewModel: FitnessViewModel

    @State private var path: [FitnessRoute] = []
    @State private var showCreateSheet = false
    @State private var showAssignDaySheet = false
    @State private var assignDayIso: Int?
    @State private var openSessionSwipeID: String?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    trainingWeekSection
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        path.append(.templates)
                    } label: {
                        templatesToolbarButton
                    }
                    .accessibilityLabel("Schema's")

                    Button {
                        path.append(.exerciseLibrary)
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 42, height: 42)
                            .background(Theme.Colors.surface2)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Oefeningen")
                }
            }
            .navigationDestination(for: FitnessRoute.self) { route in
                switch route {
                case .templates:
                    WorkoutTemplatesView()
                case .exerciseLibrary:
                    ExerciseLibraryView()
                case .template(let template):
                    WorkoutTemplateView(template: template)
                case .session:
                    WorkoutSessionView(path: $path)
                case .summary:
                    WorkoutSummaryView(path: $path)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTemplateSheet { name in
                Task {
                    if let created = await fitnessViewModel.createTemplate(name: name, dayOfWeek: nil) {
                        path.append(.template(created))
                    }
                }
            }
            .adaptiveBottomSheet()
        }
        .sheet(isPresented: $showAssignDaySheet) {
            if let day = assignDayIso {
                AssignDayTemplateSheet(
                    isoDay: day,
                    templates: fitnessViewModel.templates,
                    onPick: { template in
                        showAssignDaySheet = false
                        Task { await fitnessViewModel.assignTemplate(template, toIsoDay: day) }
                    },
                    onCreateSchema: {
                        showAssignDaySheet = false
                        showCreateSheet = true
                    }
                )
                .adaptiveBottomSheet()
            }
        }
        .task { await fitnessViewModel.refresh() }
        .alert(
            "Er ging iets mis",
            isPresented: Binding(
                get: { fitnessViewModel.errorMessage != nil },
                set: { if !$0 { fitnessViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { fitnessViewModel.errorMessage = nil }
        } message: {
            Text(fitnessViewModel.errorMessage ?? "")
        }
    }

    // MARK: - Weekoverzicht

    private var trainingWeekSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            weekProgressCard
            todayCard
            weekListSection
        }
    }

    private var weekProgressCard: some View {
        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deze week")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.Colors.textMuted)
                            .tracking(0.7)
                        Text(fitnessViewModel.motivationText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }
                    Spacer()
                    if fitnessViewModel.plannedCount > 0 {
                        Text("\(fitnessViewModel.completedCount)/\(fitnessViewModel.plannedCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.green)
                            .monospacedDigit()
                    }
                }

                TrainingWeekDotBar(states: fitnessViewModel.weekDotStates())

                HStack {
                    Spacer()
                    Button { showCreateSheet = true } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "plus")
                            Text("Nieuw schema")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.green)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        let template = fitnessViewModel.todayTemplate
        let session = fitnessViewModel.todaySession
        let isDone = session?.isFinished == true

        StyledCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Vandaag")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)
                    .tracking(0.7)

                if isDone, let session {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Training afgerond")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            Text(fitnessViewModel.templateName(for: session))
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textMuted)
                        }
                        Spacer()
                        if session.elapsedSeconds > 0 {
                            Text("\(session.elapsedSeconds / 60) min")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.green)
                                .monospacedDigit()
                        }
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.Colors.green)
                    }
                } else if let template {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(template.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        PrimaryButton(
                            title: "Start training",
                            icon: "play.fill",
                            action: { startSession(template: template) },
                            color: Theme.Colors.green
                        )
                    }
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Geen training gepland")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        Text("Koppel een schema aan vandaag in je weekoverzicht.")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.textMuted)
                        PrimaryButton(
                            title: "Kies schema",
                            icon: "calendar.badge.plus",
                            action: {
                                assignDayIso = fitnessViewModel.todayIsoDay
                                showAssignDaySheet = true
                            },
                            color: Theme.Colors.green
                        )
                    }
                }
            }
        }
    }

    private var weekListSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionLabel("Weekoverzicht", icon: "calendar")

            if fitnessViewModel.templates.isEmpty {
                StyledCard {
                    Text("Maak een schema aan en koppel het aan een dag hieronder.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(fitnessViewModel.weekDates, id: \.self) { date in
                    weekDayRow(for: date)
                }
            }
        }
    }

    @ViewBuilder
    private func weekDayRow(for date: Date) -> some View {
        let isoDay = WorkoutWeekday.isoWeekday(from: date)
        let template = fitnessViewModel.template(forIsoDay: isoDay)
        let session = fitnessViewModel.session(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        let isPast = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
        let isDone = session?.isFinished == true
        let isMissed = template != nil && !isDone && isPast

        let row = WeekDayRow(
            date: date,
            template: template,
            session: isDone ? session : nil,
            isToday: isToday,
            isMissed: isMissed
        )

        if let session, isDone {
            SwipeableActionRow(
                id: session.id.uuidString,
                openID: $openSessionSwipeID,
                onDelete: {
                    Task { await fitnessViewModel.deleteSession(session) }
                }
            ) {
                row
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(rowBackground(isToday: isToday))
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        } else {
            Button {
                handleDayTap(isoDay: isoDay, template: template)
            } label: {
                row
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(rowBackground(isToday: isToday))
                    .cornerRadius(Theme.Radius.md)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowBackground(isToday: Bool) -> Color {
        isToday ? Theme.Colors.green.opacity(0.1) : Theme.Colors.surface
    }

    private func handleDayTap(isoDay: Int, template: WorkoutTemplate?) {
        if let template {
            path.append(.template(template))
        } else {
            assignDayIso = isoDay
            showAssignDaySheet = true
        }
    }

    private var templatesToolbarButton: some View {
        Image(systemName: "square.stack.3d.up.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Theme.Colors.text)
            .frame(width: 42, height: 42)
            .background(Theme.Colors.surface2)
            .clipShape(Circle())
    }

    // MARK: - Actions

    private func startSession(template: WorkoutTemplate?) {
        Task {
            await fitnessViewModel.startSession(
                dateIso: DayFormatting.isoString(from: Date()),
                template: template
            )
            if fitnessViewModel.activeSession != nil {
                path.append(.session)
            }
        }
    }
}

// MARK: - Subviews

private struct WeekDayRow: View {
    let date: Date
    let template: WorkoutTemplate?
    let session: WorkoutSession?
    let isToday: Bool
    let isMissed: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(WorkoutWeekday.shortLabel(for: WorkoutWeekday.isoWeekday(from: date)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isToday ? Theme.Colors.green : Theme.Colors.textMuted)
                Text(shortDateLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textDim)
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 15, weight: template != nil || session != nil ? .semibold : .regular))
                    .foregroundColor(titleColor)

                if let session, session.isFinished, session.elapsedSeconds > 0 {
                    Text("\(session.elapsedSeconds / 60) min")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                        .monospacedDigit()
                } else if isMissed {
                    Text("Gemist")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.tomato.opacity(0.85))
                }
            }

            Spacer()

            trailingIcon
        }
    }

    private var titleText: String {
        if let session, session.isFinished {
            return template?.name ?? "Training"
        }
        return template?.name ?? "Kies schema"
    }

    private var titleColor: Color {
        if session?.isFinished == true || template != nil {
            return Theme.Colors.text
        }
        return Theme.Colors.textDim
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if session?.isFinished == true {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.green)
        } else if template != nil {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
        } else {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
        }
    }

    private var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Sheets

private struct AssignDayTemplateSheet: View {
    let isoDay: Int
    let templates: [WorkoutTemplate]
    let onPick: (WorkoutTemplate) -> Void
    let onCreateSchema: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionLabel(
                WorkoutWeekday.label(for: isoDay),
                icon: "calendar"
            )

            Text("Kies een schema voor deze dag")
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textMuted)

            if templates.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Je hebt nog geen schema's. Maak er eerst een aan.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.textMuted)

                    PrimaryButton(
                        title: "Schema aanmaken",
                        icon: "plus.circle.fill",
                        action: onCreateSchema,
                        color: Theme.Colors.green
                    )
                }
            } else {
                ForEach(templates) { template in
                    Button {
                        onPick(template)
                    } label: {
                        assignOptionRow(
                            title: template.name,
                            subtitle: template.planLabel,
                            icon: "square.stack.3d.up.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveSheetContentHeight()
        .background(Theme.Colors.background)
    }

    private func assignOptionRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.Radius.md)
    }
}
