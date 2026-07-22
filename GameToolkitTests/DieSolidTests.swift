import Testing
import simd
@testable import Game_Toolkit

@Suite("Die solids")
struct DieSolidTests {

    @Test("Each side count maps to the right polyhedron", arguments: [
        (4, 4), (6, 6), (8, 8), (10, 10), (12, 12), (20, 20), (100, 10),
    ])
    func faceCounts(sides: Int, expectedFaces: Int) {
        #expect(DieSolid.solid(for: sides).faces.count == expectedFaces)
    }

    @Test("Unusual side counts fall back to the cube")
    func fallback() {
        #expect(DieSolid.solid(for: 7).faces.count == 6)
        #expect(DieSolid.solid(for: 2).faces.count == 6)
    }

    @Test("Every solid has one label slot per face")
    func slotCounts() {
        #expect(DieSolid.tetrahedron.slotCount == 4)
        #expect(DieSolid.icosahedron.slotCount == 20)
        for solid in [DieSolid.tetrahedron, .cube, .octahedron, .trapezohedron, .dodecahedron, .icosahedron] {
            #expect(solid.slotCount == solid.faces.count)
        }
    }

    @Test("Face normals are unit length and point away from the center")
    func normals() {
        for solid in [DieSolid.tetrahedron, .cube, .octahedron, .trapezohedron, .dodecahedron, .icosahedron] {
            for face in solid.faces {
                #expect(abs(simd_length(face.normal) - 1) < 1e-9)
                #expect(simd_dot(face.normal, face.center) > 0)
                // The in-plane basis is orthonormal and right-handed with the normal.
                #expect(abs(simd_dot(face.u, face.v)) < 1e-9)
                #expect(simd_length(simd_cross(face.u, face.v) - face.normal) < 1e-6)
            }
        }
    }

    @Test("Every face of a solid has the same vertex count")
    func regularFaces() {
        let expected: [(DieSolid, Int)] = [
            (.tetrahedron, 3), (.cube, 4), (.octahedron, 3),
            (.trapezohedron, 4), (.dodecahedron, 5), (.icosahedron, 3),
        ]
        for (solid, count) in expected {
            #expect(solid.faces.allSatisfy { $0.vertexIndices.count == count })
        }
    }

    @Test("Settle pose points the slot at the viewer (within the presentation lean)")
    func settlePose() {
        for solid in [DieSolid.tetrahedron, .cube, .octahedron, .trapezohedron, .dodecahedron, .icosahedron] {
            for slot in 0..<solid.slotCount {
                let pose = DieTrajectory.restPose(solid: solid, slot: slot, restingYawDegrees: 2)
                let up = pose.act(solid.slotDirections[slot])
                // The fixed ~14° presentation lean keeps side faces visible, so the
                // slot is near — not exactly on — the camera axis.
                #expect(up.z > 0.95, "slot \(slot) of \(solid.name) should face the viewer")
            }
        }
    }

    @Test("Rest labels put the rolled value on top and honor the opposite-face sum")
    func restLabels() {
        let labels = DieTrajectory.restLabels(
            value: 3, topSlot: 2, sides: 8, solid: .octahedron, seed: 42
        )
        #expect(labels.count == 8)
        #expect(labels[2] == 3)
        if let opposite = DieSolid.octahedron.oppositeSlot(of: 2) {
            #expect(labels[opposite] == 6)
        }
        #expect(labels.sorted() == Array(1...8))
    }

    @Test("A generated trajectory settles exactly on its reported slot")
    func trajectorySettles() {
        let solid = DieSolid.icosahedron
        let trajectory = DieTrajectory.generate(
            seed: 0xFEED,
            sides: 20,
            solid: solid,
            startOrientation: DieTrajectory.restPose(solid: solid, slot: 0, restingYawDegrees: 0),
            restingYawDegrees: 0
        )
        let up = trajectory.finalOrientation.act(solid.slotDirections[trajectory.settleSlot])
        #expect(up.z > 0.95)
        #expect(trajectory.duration > 0.9)
    }
}

@Suite("Dice bags")
struct DiceBagTests {

    @Test("Die specs survive the JSON round-trip through a bag")
    @MainActor
    func bagRoundTrip() {
        let dice = [
            DieSpec(sides: 20, faceHex: "#112233", pipHex: "#FFFFFF"),
            DieSpec(sides: 6),
        ]
        let bag = DiceBag(name: "Test", dice: dice)
        #expect(bag.dice == dice)
        #expect(bag.boxName == DiceBag.defaultBox)
    }
}
