import SwiftUI
import Combine
import UIKit
import Charts

// MARK: - Simple models & storage (UserDefaults)
struct Entry: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var date: String   // "yyyy-MM-dd"
    var mood: String   // "good"/"meh"/"bad"
    var note: String
}

final class Store: ObservableObject {
    @Published var username: String = "guest" { didSet { saveUser(); loadEntries() } }
    @Published var displayName: String = ""   { didSet { saveUser() } }
    @Published var entries: [Entry] = []

    private let userKey = "ms_user"
    private func entriesKey(_ u: String) -> String { "ms_entries_\(u)" }

    init() { loadUser(); loadEntries() }

    // MARK: User
    struct User: Codable { var username: String; var displayName: String }

    func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let u = try? JSONDecoder().decode(User.self, from: data) {
            username = u.username; displayName = u.displayName
        }
    }

    func saveUser() {
        let u = User(username: username, displayName: displayName)
        if let data = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    // MARK: Entries
    func loadEntries() {
        let key = entriesKey(username)
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = arr.sorted { $0.date > $1.date }
        } else {
            entries = []
        }
    }

    private func persist() {
        let key = entriesKey(username)
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ e: Entry)          { entries.insert(e, at: 0); persist() }
    func update(_ e: Entry)       { if let i = entries.firstIndex(where: { $0.id == e.id }) { entries[i] = e; persist() } }
    func delete(_ id: String)     { entries.removeAll { $0.id == id }; persist() }

    // MARK: - Chart helpers
    func moodScore(_ mood: String) -> Int { mood == "bad" ? 1 : (mood == "meh" ? 2 : 3) }

    func last7Dates() -> [String] {
        var out: [String] = []
        let cal = Calendar.current
        for i in (0..<7).reversed() {
            if let d = cal.date(byAdding: .day, value: -i, to: Date()) {
                out.append(Self.yyyyMMdd.string(from: d))
            }
        }
        return out
    }

    func score(on date: String) -> Int? {
        entries.first(where: { $0.date == date }).map { moodScore($0.mood) }
    }

    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .init(identifier: .iso8601)
        f.locale   = .init(identifier: "en_US_POSIX")
        f.timeZone = .init(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - Routing enum for tabs / deep links
enum Route: Hashable {
    case home
    case dashboard(user: String?)
    case journal
    case new(id: String?)
    case profile

    static func from(url: URL) -> Route {
        let scheme = (url.scheme ?? "").lowercased()
        let host   = (url.host ?? "").lowercased()
        let path   = url.path.lowercased()

        func q(_ name: String) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == name })?.value
        }

        // Custom scheme: moodsync://dashboard?u=...
        if scheme == "moodsync" {
            if host == "dashboard" || path.contains("/dashboard") { return .dashboard(user: q("u")) }
            if host == "journal"   || path.contains("/journal")   { return .journal }
            if host == "new"       || path.contains("/new")       { return .new(id: q("id")) }
        }

        // Universal Link later: https://yourdomain/ul/app?u=...
        if scheme == "https", path.hasPrefix("/ul/app") {
            return .dashboard(user: q("u"))
        }

        return .home
    }

    /// Which tab should be selected for a given deep link
    var tab: Route {
        switch self {
        case .home:                      return .home
        case .dashboard:                 return .dashboard(user: nil)
        case .journal, .new:             return .journal
        case .profile:                   return .profile
        }
    }
}

// MARK: - ContentView (everything here)
struct ContentView: View {
    @StateObject private var store = Store()
    @State private var route: Route = .home

    // New/Edit sheet state
    @State private var showEditor = false
    @State private var editEntry: Entry? = nil

    // Home extras
    @State private var dailyQuote: String = [
        "Every emotion is valid just notice it.",
        "Small wins count too. Keep going.",
        "You’ve survived 100% of your hardest days.",
        "Be kind to your mind today.",
        "Progress, not perfection."
    ].randomElement()!

    var body: some View {
        TabView(selection: Binding(
            get: { route.tab },
            set: { route = $0 }
        )) {
            Home
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Route.home)

            Dashboard
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Route.dashboard(user: nil))

            Journal
                .tabItem { Label("Journal", systemImage: "book") }
                .tag(Route.journal)

            ProfilePane()
                .environmentObject(store)
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(Route.profile)
        }
        // Handle deep links here
        .onOpenURL { url in
            let r = Route.from(url: url)
            route = r.tab

            switch r {
            case .dashboard(let user):
                if let u = user, !u.isEmpty, u != store.username {
                    store.username = u
                }
            case .new(let id):
                if let id, let existing = store.entries.first(where: { $0.id == id }) {
                    editEntry = existing
                } else {
                    editEntry = Entry(date: Self.todayISO(), mood: "good", note: "")
                }
                showEditor = true
            case .journal, .home, .profile:
                break
            }
        }
        // Present editor sheet when needed
        .sheet(isPresented: $showEditor) {
            EntryEditor(entry: editEntry, onSave: { e in
                if store.entries.contains(where: { $0.id == e.id }) { store.update(e) }
                else { store.add(e) }
                showEditor = false
            })
            .environmentObject(store)
        }
        .environmentObject(store)
    }

    // MARK: Tabs
    private var Home: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Greeting
            VStack(alignment: .leading, spacing: 4) {
                let name = (store.displayName.isEmpty ? store.username : store.displayName)
                Text("Hi, \(name) 👋")
                    .font(.title).bold()
                Text("How are you feeling today?")
                    .foregroundStyle(.secondary)
            }

            // Mood quick picker
            HStack(spacing: 18) {
                ForEach(["good","meh","bad"], id: \.self) { mood in
                    Button {
                        upsertToday(mood: mood)
                    } label: {
                        VStack(spacing: 6) {
                            Text(emoji(mood)).font(.system(size: 38))
                            Text(mood.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 90, height: 90)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Mini weekly chart
            VStack(alignment: .leading, spacing: 8) {
                Text("This week’s mood")
                    .font(.headline)
                Chart {
                    ForEach(store.last7Dates(), id: \.self) { date in
                        if let score = store.score(on: date) {
                            BarMark(
                                x: .value("Day", String(date.suffix(5))),
                                y: .value("Mood", score)
                            )
                        } else {
                            BarMark( // keep axis alignment for missing days
                                x: .value("Day", String(date.suffix(5))),
                                y: .value("Mood", 0)
                            ).opacity(0.15)
                        }
                    }
                }
                .frame(height: 140)
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [1,2,3]) { v in
                        AxisValueLabel {
                            if let val = v.as(Int.self) {
                                Text(val == 1 ? "Bad" : (val == 2 ? "Meh" : "Good"))
                            }
                        }
                    }
                }
            }

            // Daily quote
            HStack(alignment: .top, spacing: 8) {
                Text("💬").font(.title3)
                Text(dailyQuote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var Dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("This Week").font(.title2).bold()

                Chart {
                    ForEach(store.last7Dates(), id: \.self) { date in
                        if let score = store.score(on: date) {
                            LineMark(
                                x: .value("Day", String(date.suffix(5))),
                                y: .value("Score", score)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(.circle)
                        }
                    }
                }
                .frame(height: 220)
                .chartYScale(domain: 1...3)
                .chartYAxis {
                    AxisMarks(values: [1,2,3]) { v in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let val = v.as(Int.self) {
                                Text(val == 1 ? "Bad" : (val == 2 ? "Meh" : "Good"))
                            }
                        }
                    }
                }

                Text("Quick Stats").font(.title3).bold()

                HStack {
                    StatCard(title: "Good 😊", value: count("good"))
                    StatCard(title: "Meh 😐",  value: count("meh"))
                    StatCard(title: "Bad ☁️",  value: count("bad"))
                }
            }
            .padding()
        }
    }

    private var Journal: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Entries").font(.title2).bold()
                Spacer()
                Button("New") {
                    editEntry = Entry(id: UUID().uuidString,
                                      date: Self.todayISO(),
                                      mood: "good",
                                      note: "")
                    showEditor = true
                }
                .buttonStyle(.borderedProminent)
            }

            if store.entries.isEmpty {
                ContentUnavailableView("No entries yet",
                                       systemImage: "book",
                                       description: Text("Tap **New** to add your first reflection."))
                Spacer()
            } else {
                List {
                    ForEach(store.entries) { e in
                        HStack(alignment: .top, spacing: 12) {
                            Text(emoji(e.mood)).font(.title2)
                            VStack(alignment: .leading) {
                                Text(e.date).bold()
                                Text(e.note).lineLimit(2)
                            }
                            Spacer()
                            Button("Edit") {
                                editEntry = e
                                showEditor = true
                            }
                            .buttonStyle(.bordered)
                            Button("Delete", role: .destructive) {
                                store.delete(e.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: helpers
    func count(_ mood: String) -> Int { store.entries.filter { $0.mood == mood }.count }

    static func todayISO() -> String {
        let f = DateFormatter()
        f.calendar = .init(identifier: .iso8601)
        f.locale   = .init(identifier: "en_US_POSIX")
        f.timeZone = .init(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func emoji(_ m: String) -> String { m == "good" ? "😊" : (m == "meh" ? "😐" : "☁️") }

    /// Save or update today's mood quickly from the Home screen
    private func upsertToday(mood: String) {
        let today = Self.todayISO()
        if let idx = store.entries.firstIndex(where: { $0.date == today }) {
            var e = store.entries[idx]
            e.mood = mood
            store.update(e)
        } else {
            store.add(Entry(date: today, mood: mood, note: ""))
        }
    }
}

// MARK: - Profile Pane (separate mini view so we can show a toast)
struct ProfilePane: View {
    @EnvironmentObject var store: Store
    @State private var showSaved = false

    var body: some View {
        ZStack {
            Form {
                // Status chip
                Section {
                    HStack(spacing: 8) {
                        Circle().frame(width: 8, height: 8).foregroundStyle(.green)
                        Text("Logged in as ")
                        Text(displayNameOrUsername).bold()
                        Spacer()
                    }
                }

                Section("Profile") {
                    TextField("Username", text: $store.username)
                    TextField("Display Name", text: $store.displayName)
                    Button("Save") {
                        store.saveUser()
                        withAnimation(.spring) { showSaved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut) { showSaved = false }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Links") {
                    Button("View My Journal Online") {
                        let u = store.username.isEmpty ? "guest" : store.username
                        if let url = URL(string: "https://moodsync.example/u/?u=\(u)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            if showSaved {
                BannerToast(
                    text: "\(displayNameOrUsername) is logged in right now",
                    systemImage: "checkmark.circle.fill"
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle("Profile")
    }

    private var displayNameOrUsername: String {
        let n = store.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? store.username : n
    }
}

// MARK: - Small reusable UI bits
struct StatCard: View {
    var title: String
    var value: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value)").font(.title3).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 1)
        )
    }
}

struct BannerToast: View {
    var text: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .imageScale(.medium)
            Text(text).bold()
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Entry Editor (sheet)
struct EntryEditor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State var entry: Entry
    var onSave: (Entry) -> Void

    init(entry: Entry?, onSave: @escaping (Entry) -> Void) {
        _entry = State(initialValue: entry ?? Entry(date: ContentView.todayISO(), mood: "good", note: ""))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { toDate(entry.date) },
                        set: { entry.date = fromDate($0) }
                    ),
                    displayedComponents: .date
                )

                Picker("Mood", selection: $entry.mood) {
                    Text("😊 Good").tag("good")
                    Text("😐 Meh").tag("meh")
                    Text("☁️ Bad").tag("bad")
                }

                TextField("Reflection…", text: $entry.note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            .navigationTitle("Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(entry) }
                }
            }
        }
    }

    func toDate(_ iso: String) -> Date {
        Store.yyyyMMdd.date(from: iso) ?? Date()
    }

    func fromDate(_ d: Date) -> String {
        Store.yyyyMMdd.string(from: d)
    }
}

#Preview { ContentView() }
