import Foundation
import simd

/// Deterministic seeded RNG so a die's whole tumble replays identically from one seed.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    mutating func range(_ r: ClosedRange<Double>) -> Double {
        r.lowerBound + unit() * (r.upperBound - r.lowerBound)
    }
}

/// A fully precomputed tumble: a rigid-body-style integration sampled at 120 Hz.
///
/// The throw ramps up over the first tenth of a second, drifts chaotically while
/// fast, loses energy exponentially, gets kicked on every bounce, and finally
/// springs onto whichever face physics left pointing at the viewer. Precomputing
/// keeps rendering a pure function of elapsed time — cheap, deterministic, and
/// safe to interrupt with a re-roll.
struct DieTrajectory {
    static let sampleRate: Double = 120

    let samples: [simd_quatd]
    let hops: [Double]
    let duration: TimeInterval
    /// The label slot (face, or vertex for the d4) left pointing at the viewer;
    /// it displays the engine's live value.
    let settleSlot: Int
    /// Values shown on the other slots mid-tumble.
    let sideLabels: [Int]

    var finalOrientation: simd_quatd { samples.last ?? simd_quatd(angle: 0, axis: [0, 0, 1]) }

    func orientation(at t: TimeInterval) -> simd_quatd {
        guard let last = samples.last else { return simd_quatd(angle: 0, axis: [0, 0, 1]) }
        let x = max(0, t) * Self.sampleRate
        let i = Int(x)
        guard i < samples.count - 1 else { return last }
        return simd_normalize(simd_slerp(samples[i], samples[i + 1], x - Double(i)))
    }

    func hop(at t: TimeInterval) -> Double {
        guard !hops.isEmpty else { return 0 }
        let x = max(0, t) * Self.sampleRate
        let i = Int(x)
        guard i < hops.count - 1 else { return 0 }
        let f = x - Double(i)
        return hops[i] * (1 - f) + hops[i + 1] * f
    }

    static func generate(
        seed: UInt64,
        sides: Int,
        solid: DieSolid,
        startOrientation: simd_quatd,
        restingYawDegrees: Double
    ) -> DieTrajectory {
        var rng = SplitMix64(seed: seed)
        var q = simd_normalize(startOrientation)

        // Spin axis mostly in the screen plane so the die turns over its edges
        // (a z-axis spin would just pirouette without showing new faces).
        var w = simd_normalize(simd_double3(
            rng.range(-1...1), rng.range(-1...1), rng.range(-0.35...0.35)
        )) * rng.range(17...27)

        var height = 0.0
        var vz = rng.range(2.2...3.4)
        let gravity = 10.0
        let restitution = rng.range(0.4...0.55)

        var samples: [simd_quatd] = []
        var hops: [Double] = []
        let dt = 1.0 / sampleRate
        var t = 0.0
        let minTumble = 0.9

        while t < 2.5 {
            // Wind-up: the throw builds to full spin over the first tenth of a second.
            let ramp = min(1, t / 0.1)
            // Chaotic drift while the die is still fast.
            if t < 0.45 {
                w += simd_double3(rng.range(-1...1), rng.range(-1...1), rng.range(-0.5...0.5)) * (26 * dt)
            }
            w *= exp(-2.6 * dt)

            let effective = w * ramp
            let angle = simd_length(effective) * dt
            if angle > 1e-9 {
                q = simd_normalize(simd_quatd(angle: angle, axis: simd_normalize(effective)) * q)
            }

            // Vertical hop; each bounce kicks the spin, so landings stay chaotic.
            vz -= gravity * dt
            height += vz * dt
            if height < 0 {
                height = 0
                if abs(vz) > 0.4 {
                    vz = -vz * restitution
                    w += simd_double3(rng.range(-1...1), rng.range(-1...1), 0) * abs(vz) * 2.2
                } else {
                    vz = 0
                }
            }

            samples.append(q)
            hops.append(height)
            t += dt

            if t > minTumble, simd_length(effective) < 1.6, height == 0 { break }
        }

        var settleSlot = 0
        var best = -2.0
        for (i, direction) in solid.slotDirections.enumerated() {
            let z = q.act(direction).z
            if z > best {
                best = z
                settleSlot = i
            }
        }

        // Roll to rest, as two blended motions that continue the tumble's leftover
        // spin. A tip spring lays the settling face flat while the twist stays
        // free, and a gentler yaw spring pivots the die flat on the felt until the
        // face reads upright (nearest quarter turn for the pip cube). Because
        // neither spring chases a fixed keyframe pose, the die visibly rolls into
        // place — nothing ever yanks it backward to a canned orientation.
        let tilt = presentationTilt
        var p = simd_normalize(tilt.inverse * q)
        var spin = tilt.inverse.act(w)
        let direction = solid.slotDirections[settleSlot]
        let uAxis = solid.faces[settleSlot].u
        let restYawRad = restingYawDegrees * .pi / 180
        var elapsed = 0.0
        while elapsed < 1.6 {
            // Tip error: the shortest arc that lays the settling face flat.
            let n = p.act(direction)
            let tipAngle = acos(min(1, max(-1, simd_dot(n, [0, 0, 1]))))
            var tipAxis = simd_cross(n, [0, 0, 1])
            let tipLen = simd_length(tipAxis)
            tipAxis = tipLen > 1e-9 ? tipAxis / tipLen : [1, 0, 0]

            // Twist error: where the numeral points versus where it should rest.
            let world = p.act(uAxis)
            let twist = atan2(world.y, world.x)
            let targetTwist: Double
            switch solid.twistSnap {
            case .quarter:
                targetTwist = ((twist - restYawRad) / (.pi / 2)).rounded() * (.pi / 2) + restYawRad
            case .upright:
                targetTwist = restYawRad
            }
            var yawError = (targetTwist - twist).remainder(dividingBy: 2 * .pi)
            // A dead-opposite numeral pivots whichever way the die already spins.
            if abs(yawError) > .pi * 0.97 { yawError = spin.z >= 0 ? abs(yawError) : -abs(yawError) }

            spin += tipAxis * tipAngle * (120 * dt)
            spin += simd_double3(0, 0, 1) * (yawError * 42 * dt)
            spin *= exp(-13 * dt)

            let step = simd_length(spin) * dt
            if step > 1e-9 {
                p = simd_normalize(simd_quatd(angle: step, axis: simd_normalize(spin)) * p)
            }
            samples.append(simd_normalize(tilt * p))
            hops.append(0)
            elapsed += dt
            if tipAngle < 0.01, abs(yawError) < 0.01, simd_length(spin) < 0.12 { break }
        }
        // Pin the exact pose, computed from the converged orientation so the final
        // sample is at most a fraction of a degree away — invisible, but it keeps
        // rest labels and later re-rolls starting from a bit-exact pose.
        let target = settleTarget(
            from: simd_normalize(tilt * p), solid: solid, slot: settleSlot,
            restingYawDegrees: restingYawDegrees
        )
        samples.append(target)
        hops.append(0)

        return DieTrajectory(
            samples: samples,
            hops: hops,
            duration: Double(samples.count) / sampleRate,
            settleSlot: settleSlot,
            sideLabels: sideLabels(sides: sides, solid: solid, using: &rng)
        )
    }

    /// The orientation an unrolled die rests in: `slot` facing the viewer, numeral
    /// upright, with the die's resting tilt.
    static func restPose(solid: DieSolid, slot: Int, restingYawDegrees: Double) -> simd_quatd {
        settleTarget(
            from: simd_quatd(angle: 0, axis: [0, 0, 1]),
            solid: solid, slot: slot, restingYawDegrees: restingYawDegrees
        )
    }

    /// A gentle fixed lean applied to every settled die so two side faces stay
    /// visible — a face dead-on to the camera reads as a flat tile, not a solid.
    private static let presentationTilt: simd_quatd =
        simd_quatd(angle: 12 * .pi / 180, axis: [1, 0, 0])
            * simd_quatd(angle: -8 * .pi / 180, axis: [0, 1, 0])

    /// The exact orientation that points `slot` at the viewer (plus the standing
    /// presentation lean). The pip cube snaps to the nearest quarter turn for the
    /// smallest visible correction; numeral faces rotate until the number reads
    /// upright.
    private static func settleTarget(
        from q: simd_quatd, solid: DieSolid, slot: Int, restingYawDegrees: Double
    ) -> simd_quatd {
        let direction = solid.slotDirections[slot]
        let align = shortestArc(from: q.act(direction), to: [0, 0, 1])
        let aligned = simd_normalize(align * q)

        let world = aligned.act(solid.faces[slot].u)
        let twist = atan2(world.y, world.x)

        let yaw: Double
        switch solid.twistSnap {
        case .quarter:
            yaw = (twist / (.pi / 2)).rounded() * (.pi / 2) - twist
        case .upright:
            yaw = -twist
        }
        let upright = simd_quatd(angle: yaw + restingYawDegrees * .pi / 180, axis: [0, 0, 1]) * aligned
        return simd_normalize(presentationTilt * upright)
    }

    private static func shortestArc(from a: simd_double3, to b: simd_double3) -> simd_quatd {
        let d = simd_dot(a, b)
        if d > 0.99999 { return simd_quatd(angle: 0, axis: [0, 0, 1]) }
        if d < -0.99999 {
            let axis = abs(a.x) < 0.9 ? simd_normalize(simd_cross(a, [1, 0, 0]))
                                      : simd_normalize(simd_cross(a, [0, 1, 0]))
            return simd_quatd(angle: .pi, axis: axis)
        }
        return simd_normalize(simd_quatd(real: 1 + d, imag: simd_cross(a, b)))
    }

    /// Random values for the non-settling slots while the die is in motion. When
    /// the solid has exactly one slot per side (d4, d6, d8, …) this is a true
    /// permutation of the die's values.
    private static func sideLabels(sides: Int, solid: DieSolid, using rng: inout SplitMix64) -> [Int] {
        if sides == solid.slotCount {
            return Array(1...sides).shuffled(using: &rng)
        }
        return (0..<solid.slotCount).map { _ in Int(rng.next() % UInt64(max(1, sides))) + 1 }
    }

    /// Labels for a die at rest: the top slot carries the real value, and when the
    /// solid matches the side count the hidden opposite slot keeps the classic
    /// "opposite faces sum to sides + 1" convention.
    static func restLabels(value: Int, topSlot: Int, sides: Int, solid: DieSolid, seed: UInt64) -> [Int] {
        var rng = SplitMix64(seed: seed &+ 0xD1CE)
        var labels = [Int](repeating: 1, count: solid.slotCount)
        let opposite = solid.oppositeSlot(of: topSlot)
        if sides == solid.slotCount, (1...sides).contains(value) {
            let complement = sides + 1 - value
            var rest = (1...sides)
                .filter { $0 != value && (opposite == nil || $0 != complement) }
                .shuffled(using: &rng)
            for i in labels.indices {
                if i == topSlot {
                    labels[i] = value
                } else if let opposite, i == opposite {
                    labels[i] = complement
                } else {
                    labels[i] = rest.removeLast()
                }
            }
        } else {
            for i in labels.indices {
                var v = Int(rng.next() % UInt64(max(1, sides))) + 1
                if v == value && sides > 1 { v = v % sides + 1 }
                labels[i] = v
            }
            labels[topSlot] = value
        }
        return labels
    }
}
