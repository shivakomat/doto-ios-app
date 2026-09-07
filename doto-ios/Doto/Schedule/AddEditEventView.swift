import SwiftUI

struct EventCreateRequest: Encodable {
    let title: String
    let startAt: Date
    let endAt: Date
    let description: String?
    let location: String?
    let color: String?
    let assignedTo: [String]
    let repeatRule: String?
    let repeatEndAt: Date?

    private enum CodingKeys: String, CodingKey {
        case title, startAt, endAt, description, location, color, assignedTo, repeatRule, repeatEndAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(startAt, forKey: .startAt)
        try c.encode(endAt, forKey: .endAt)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(location, forKey: .location)
        try c.encodeIfPresent(color, forKey: .color)
        try c.encode(assignedTo, forKey: .assignedTo)
        try c.encode(repeatRule, forKey: .repeatRule)
        try c.encode(repeatEndAt, forKey: .repeatEndAt)
    }
}

struct CreateEventsResponse: Decodable {
    let events: [DotoEvent]

    init(from decoder: Decoder) throws {
        if let array = try? [DotoEvent](from: decoder) {
            events = array
        } else {
            events = [try DotoEvent(from: decoder)]
        }
    }
}

struct AddEditEventView: View {
    let event: DotoEvent?
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endDate = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    @State private var location = ""
    @State private var notes = ""
    @State private var repeatOption = "none"
    @State private var repeatEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var assignedTo: Set<String> = []
    @State private var members: [Profile] = []
    @State private var timeError: String? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteAlert = false

    private let repeatOptions = ["none", "daily", "weekly", "monthly", "yearly"]
    private var isEdit: Bool { event != nil }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                }

                Section {
                    DatePicker("Starts", selection: $date, displayedComponents: .date)
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: $endDate, displayedComponents: .date)
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _ in validateTimes() }
                        .onChange(of: endDate) { _ in validateTimes() }
                        .onChange(of: startTime) { _ in validateTimes() }
                        .onChange(of: date) { _ in validateTimes() }
                    if let err = timeError {
                        Text(err).font(.caption).foregroundColor(.red)
                    }
                }

                Section(header: Text("Repeat")) {
                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(repeatOptions, id: \.self) { opt in
                            Text(opt.capitalized).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: repeatOption) { _ in validateTimes() }
                    if repeatOption != "none" {
                        DatePicker("Until", selection: $repeatEndDate, displayedComponents: .date)
                            .onChange(of: repeatEndDate) { _ in validateTimes() }
                    }
                }

                Section(header: Text("Who is this for")) {
                    assigneeSelector
                }

                Section {
                    TextField("Location (optional)", text: $location)
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(
                            notes.isEmpty ? Text("Notes (optional)").foregroundColor(.textMuted).padding(4) : nil,
                            alignment: .topLeading
                        )
                }

                if isEdit {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Event")
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(isEdit ? "Edit event" : "Add event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("✕") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(title.isEmpty || assignedTo.isEmpty || timeError != nil)
                    }
                }
            }
            .confirmationDialog(
                event?.repeat_ != nil
                    ? "This is a repeating event."
                    : "Delete this event?",
                isPresented: $showDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete This Event Only", role: .destructive) {
                    Task { await delete() }
                }
                if event?.repeat_ != nil && event?.repeatEndAt != nil {
                    Button("Delete This & Following Events", role: .destructive) {
                        Task { await deleteFollowing() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .task {
            prefill()
            if let family: Family = try? await APIClient.shared.get("/families/mine") {
                members = family.members
            }
        }
    }

    @ViewBuilder
    private var assigneeSelector: some View {
        let displayed = members.isEmpty
            ? ([authVM.currentProfile].compactMap { $0 })
            : members
        ForEach(displayed) { member in
            Button {
                if assignedTo.contains(member.id) { assignedTo.remove(member.id) }
                else { assignedTo.insert(member.id) }
            } label: {
                HStack(spacing: 10) {
                    AvatarView(name: member.displayName, color: member.color, size: 28,
                               isActive: assignedTo.contains(member.id))
                        .opacity(assignedTo.contains(member.id) ? 1 : 0.3)
                    Text(member.displayName)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if assignedTo.contains(member.id) {
                        Image(systemName: "checkmark").foregroundColor(.memberBlue)
                    }
                }
            }
        }
    }

    private func prefill() {
        guard let e = event else {
            if let id = authVM.currentProfile?.id { assignedTo.insert(id) }
            return
        }
        title = e.title
        date = e.startAt
        startTime = e.startAt
        endDate = e.endAt
        endTime = e.endAt
        location = e.location ?? ""
        notes = e.description ?? ""
        repeatOption = e.repeat_ ?? "none"
        if let re = e.repeatEndAt {
            repeatEndDate = re
        }
        assignedTo = Set(e.assignedTo)
    }

    private func combinedDate(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let tc = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = tc.hour; comps.minute = tc.minute
        return cal.date(from: comps) ?? date
    }

    private func validateTimes() {
        let start = combinedDate(date: date, time: startTime)
        let end   = combinedDate(date: endDate, time: endTime)
        if end <= start {
            timeError = "End must be after start"
        } else if repeatOption != "none"
                    && combinedDate(date: repeatEndDate, time: endTime) <= start {
            timeError = "Repeat end must be after start"
        } else {
            timeError = nil
        }
    }

    private func save() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let start = combinedDate(date: date, time: startTime)
        let end   = combinedDate(date: endDate, time: endTime)
        let body  = EventCreateRequest(
            title: title,
            startAt: start,
            endAt: end,
            description: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            color: nil,
            assignedTo: Array(assignedTo),
            repeatRule: repeatOption == "none" ? nil : repeatOption,
            repeatEndAt: repeatOption != "none"
                ? combinedDate(date: repeatEndDate, time: endTime) : nil
        )
        do {
            if let e = event {
                let _: DotoEvent = try await APIClient.shared.put("/events/\(e.id)", body: body)
            } else {
                let _: CreateEventsResponse = try await APIClient.shared.post("/events", body: body)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() async {
        isLoading = true; defer { isLoading = false }
        guard let e = event else { return }
        do {
            try await APIClient.shared.delete("/events/\(e.id)")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteFollowing() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        guard let e = event else { return }
        do {
            try await APIClient.shared.delete("/events/\(e.id)?deleteFollowing=true")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
