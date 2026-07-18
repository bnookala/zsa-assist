/// Simulates a Moonlander whose user periodically holds a momentary-layer
/// key: the reported layer follows a fixed, repeating schedule derived from
/// wall-clock time since init. No state is mutated, so the type stays
/// Sendable and calls are safe from any task.
public struct StubKeymappClient: KeymappClient {
    public struct Step: Sendable {
        public let layer: Int
        public let seconds: Double

        public init(layer: Int, seconds: Double) {
            self.layer = layer
            self.seconds = seconds
        }
    }

    /// Base typing, a ~1.5s hold of layer 2, base again, then a short tap
    /// of layer 1 — enough variety to exercise show/hide logic.
    public static let defaultSchedule: [Step] = [
        Step(layer: 0, seconds: 2.0),
        Step(layer: 2, seconds: 1.5),
        Step(layer: 0, seconds: 1.0),
        Step(layer: 1, seconds: 0.5),
    ]

    private let start: ContinuousClock.Instant
    private let schedule: [Step]
    private let cycleSeconds: Double

    public init(schedule: [Step] = StubKeymappClient.defaultSchedule) {
        precondition(!schedule.isEmpty, "schedule must not be empty")
        self.start = .now
        self.schedule = schedule
        self.cycleSeconds = schedule.reduce(0) { $0 + $1.seconds }
    }

    public func status() async throws -> KeyboardStatus {
        let elapsed = start.duration(to: .now)
        let elapsedSeconds = Double(elapsed.components.seconds)
            + Double(elapsed.components.attoseconds) * 1e-18
        var position = elapsedSeconds.truncatingRemainder(dividingBy: cycleSeconds)
        var layer = schedule[0].layer
        for step in schedule {
            if position < step.seconds {
                layer = step.layer
                break
            }
            position -= step.seconds
        }
        return KeyboardStatus(friendlyName: "Moonlander (stub)", currentLayer: layer)
    }
}
