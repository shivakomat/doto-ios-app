import SwiftUI

struct EventCreateRequest: Encodable {
    let title: String
    let startAt: Date
    let endAt: Date
    let description: String?
    let location: String?
    let color: String?
    let assignedTo: [String]
}

struct AddEditEventView: View {
    let event: DotoEvent?
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    @State private var location = ""
    @State private var notes = ""
    @State private var repeatOption = "none"
    @State private var assignedTo: Set<String> = []
    @State private var members: [Profile] = []
    @State private var timeError: String? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteAlert = false

    private let repeatOptions = ["none", "daily", "weekly", "monthly"]
    private var isEdit: Bool { event != nil }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                }

                Section {
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    }
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _ in
                            if endTime <= startTime {
                                timeError = "End time must be after start time"
                            } else {
                                timeError = nil
                            }
                        }
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
            .alert("Delete this event?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { Task { await delete() } }
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
        endTime = e.endAt
        location = e.location ?? ""
        notes = e.description ?? ""
        repeatOption = e.repeat_ ?? "none"
        assignedTo = Set(e.assignedTo)
    }

    private func combinedDate(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let tc = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = tc.hour; comps.minute = tc.minute
        return cal.date(from: comps) ?? date
    }

    private func save() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let start = combinedDate(date: date, time: startTime)
        let end   = combinedDate(date: date, time: endTime)
        let body  = EventCreateRequest(
            title: title,
            startAt: start,
            endAt: end,
            description: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            color: nil,
            assignedTo: Array(assignedTo)
        )
        do {
            if let e = event {
                let _: DotoEvent = try await APIClient.shared.put("/events/\(e.id)", body: body)
            } else {
                let _: DotoEvent = try await APIClient.shared.post("/events", body: body)
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
}
