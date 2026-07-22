import Foundation
import simd

/// A convex polyhedron a die can take: the platonic solids plus the pentagonal
/// trapezohedron (the classic d10). Geometry lives in the body frame — x right,
/// y down, z toward the viewer — with every solid pre-scaled so it renders at a
/// comparable size to the original cube.
///
/// Faces are derived generically from the vertex set (every supporting plane of
/// the convex hull becomes one face), so adding a solid only takes vertices.
struct DieSolid {
    struct Face {
        let vertexIndices: [Int]
        let center: simd_double3
        let normal: simd_double3
        /// In-plane orthonormal basis with `v = normal × u`, so a numeral drawn
        /// along (u, v) reads upright when the face looks at the camera with
        /// u along screen-x.
        let u: simd_double3
        let v: simd_double3
        /// Distance from the face center to its nearest edge; sizes pips/numerals.
        let inradius: Double
    }

    /// How the in-plane twist snaps when the die settles.
    enum TwistSnap {
        /// Nearest quarter turn — for the pip cube, whose faces are 4-fold symmetric.
        case quarter
        /// Absolute: rotate until the numeral reads upright.
        case upright
    }

    let name: String
    let vertices: [simd_double3]
    let faces: [Face]
    let twistSnap: TwistSnap
    /// Body-frame directions that can point at the viewer at rest — one per face,
    /// which is also one per label slot.
    let slotDirections: [simd_double3]

    var slotCount: Int { slotDirections.count }

    /// The slot on the far side of `slot`, if the solid has one (used to keep the
    /// "opposite faces sum to sides+1" convention). The d4 has none.
    func oppositeSlot(of slot: Int) -> Int? {
        let dir = slotDirections[slot]
        return slotDirections.indices.first { simd_dot(slotDirections[$0], dir) < -0.999 }
    }

    static func solid(for sides: Int) -> DieSolid {
        switch sides {
        case 4: return .tetrahedron
        case 8: return .octahedron
        case 10, 100: return .trapezohedron
        case 12: return .dodecahedron
        case 20: return .icosahedron
        default: return .cube
        }
    }

    // MARK: - The solids

    /// Face-read rather than apex-read: on screen a centered numeral is far easier
    /// to read at a glance than a real d4's tip.
    static let tetrahedron = DieSolid(
        name: "d4",
        rawVertices: [
            [1, 1, 1], [1, -1, -1], [-1, 1, -1], [-1, -1, 1],
        ],
        scale: 1.62,
        twistSnap: .upright
    )

    static let cube = DieSolid(
        name: "d6",
        rawVertices: [
            [-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
            [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1],
        ],
        scale: 1.732,
        twistSnap: .quarter
    )

    static let octahedron = DieSolid(
        name: "d8",
        rawVertices: [
            [1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1],
        ],
        scale: 1.68,
        twistSnap: .upright
    )

    /// Pentagonal trapezohedron, built as the polar dual of a pentagonal antiprism —
    /// duality guarantees the ten kite faces come out planar.
    static let trapezohedron: DieSolid = {
        var antiprism: [simd_double3] = []
        let ringHeight = 0.55
        for k in 0..<5 {
            let top = Double(k) * .pi * 2 / 5
            let bottom = top + .pi / 5
            antiprism.append([cos(top), sin(top), ringHeight])
            antiprism.append([cos(bottom), sin(bottom), -ringHeight])
        }
        let planes = DieSolid.supportingPlanes(of: antiprism)
        let dualVertices = planes.map { $0.normal / $0.offset }
        return DieSolid(
            name: "d10",
            rawVertices: dualVertices,
            scale: 1.58,
            twistSnap: .upright
        )
    }()

    static let dodecahedron: DieSolid = {
        let phi = (1 + 5.0.squareRoot()) / 2
        var v: [simd_double3] = []
        for x in [-1.0, 1] {
            for y in [-1.0, 1] {
                for z in [-1.0, 1] { v.append([x, y, z]) }
            }
        }
        for a in [-1 / phi, 1 / phi] {
            for b in [-phi, phi] {
                v.append([0, a, b])
                v.append([a, b, 0])
                v.append([b, 0, a])
            }
        }
        return DieSolid(
            name: "d12",
            rawVertices: v,
            scale: 1.46,
            twistSnap: .upright
        )
    }()

    static let icosahedron: DieSolid = {
        let phi = (1 + 5.0.squareRoot()) / 2
        var v: [simd_double3] = []
        for a in [-1.0, 1] {
            for b in [-phi, phi] {
                v.append([0, a, b])
                v.append([a, b, 0])
                v.append([b, 0, a])
            }
        }
        return DieSolid(
            name: "d20",
            rawVertices: v,
            scale: 1.52,
            twistSnap: .upright
        )
    }()

    // MARK: - Construction

    private init(
        name: String,
        rawVertices: [simd_double3],
        scale: Double,
        twistSnap: TwistSnap
    ) {
        let circumradius = rawVertices.map(simd_length).max() ?? 1
        let scaled = rawVertices.map { $0 / circumradius * scale }
        let faces = Self.extractFaces(from: scaled)

        self.name = name
        self.vertices = scaled
        self.faces = faces
        self.twistSnap = twistSnap
        self.slotDirections = faces.map(\.normal)
    }

    private struct Plane {
        let normal: simd_double3
        let offset: Double
    }

    /// Every supporting plane of the convex hull of `vertices` (assumed to
    /// enclose the origin). Brute force over vertex triples — the solids are
    /// tiny and this runs once per solid, lazily.
    private static func supportingPlanes(of vertices: [simd_double3]) -> [Plane] {
        var planes: [Plane] = []
        let n = vertices.count
        for i in 0..<n {
            for j in (i + 1)..<n {
                for k in (j + 1)..<n {
                    let cross = simd_cross(vertices[j] - vertices[i], vertices[k] - vertices[i])
                    guard simd_length(cross) > 1e-9 else { continue }
                    var normal = simd_normalize(cross)
                    var offset = simd_dot(normal, vertices[i])
                    if offset < 0 {
                        normal = -normal
                        offset = -offset
                    }
                    guard offset > 1e-9 else { continue }
                    guard vertices.allSatisfy({ simd_dot(normal, $0) <= offset + 1e-7 }) else { continue }
                    let isNew = !planes.contains {
                        simd_length($0.normal - normal) < 1e-5 && abs($0.offset - offset) < 1e-5
                    }
                    if isNew { planes.append(Plane(normal: normal, offset: offset)) }
                }
            }
        }
        return planes
    }

    private static func extractFaces(from vertices: [simd_double3]) -> [Face] {
        supportingPlanes(of: vertices).map { plane in
            let members = vertices.indices.filter {
                abs(simd_dot(plane.normal, vertices[$0]) - plane.offset) < 1e-6
            }
            let center = members.map { vertices[$0] }.reduce(simd_double3(), +) / Double(members.count)
            let sortU = simd_normalize(vertices[members[0]] - center)
            let sortV = simd_normalize(simd_cross(plane.normal, sortU))
            let ordered = members.sorted { a, b in
                let pa = vertices[a] - center
                let pb = vertices[b] - center
                return atan2(simd_dot(pa, sortV), simd_dot(pa, sortU))
                     < atan2(simd_dot(pb, sortV), simd_dot(pb, sortU))
            }
            // Align the face basis with its first edge (not a corner), so pip grids
            // and settled numerals sit square to the face's edges.
            let u = simd_normalize(vertices[ordered[1]] - vertices[ordered[0]])
            let v = simd_normalize(simd_cross(plane.normal, u))
            var inradius = Double.greatestFiniteMagnitude
            for idx in ordered.indices {
                let a = vertices[ordered[idx]]
                let b = vertices[ordered[(idx + 1) % ordered.count]]
                let edge = b - a
                let t = simd_dot(center - a, edge) / simd_dot(edge, edge)
                inradius = min(inradius, simd_length(center - (a + edge * t)))
            }
            return Face(
                vertexIndices: ordered,
                center: center,
                normal: plane.normal,
                u: u,
                v: v,
                inradius: inradius
            )
        }
    }
}
