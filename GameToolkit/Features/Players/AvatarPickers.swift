import SwiftUI
import UIKit
#if canImport(ImagePlayground)
import ImagePlayground
#endif

// MARK: - Image sizing

/// Avatar images are stored in SwiftData (mirrored to CloudKit), so they're downscaled
/// aggressively — an avatar is at most ~120 pt on screen.
enum AvatarImage {
    static let maxDimension: CGFloat = 600

    static func downscale(_ data: Data) -> Data? {
        UIImage(data: data).flatMap(downscale)
    }

    static func downscale(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let scaled = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }
}

// MARK: - Selfie camera

/// Thin wrapper around the system camera, front-facing by default for selfies.
/// `isAvailable` is false on Macs and Vision Pro, which hides the button entirely.
struct CameraPicker: UIViewControllerRepresentable {
    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Image Playground

#if canImport(ImagePlayground)
/// "Create with Image Playground": generates an avatar from the player's name (and their
/// current photo, when they have one, so the result can be based on their selfie).
/// Renders nothing on devices without Apple Intelligence support.
@available(iOS 18.2, macCatalyst 18.2, *)
struct ImagePlaygroundAvatarButton: View {
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    let playerName: String
    let sourceImageData: Data?
    let onImage: (Data) -> Void

    @State private var isPresented = false

    private var concepts: [ImagePlaygroundConcept] {
        let trimmed = playerName.trimmingCharacters(in: .whitespaces)
        let subject = trimmed.isEmpty ? "A board game night player" : trimmed
        return [.text("\(subject), playful board-game-night avatar portrait")]
    }

    private var sourceImage: Image? {
        sourceImageData
            .flatMap(UIImage.init(data:))
            .map(Image.init(uiImage:))
    }

    var body: some View {
        if supportsImagePlayground {
            Button {
                isPresented = true
            } label: {
                Label("Create with Image Playground", systemImage: "sparkles")
            }
            .imagePlaygroundSheet(isPresented: $isPresented,
                                  concepts: concepts,
                                  sourceImage: sourceImage) { url in
                if let data = try? Data(contentsOf: url),
                   let scaled = AvatarImage.downscale(data) {
                    onImage(scaled)
                }
            }
        }
    }
}
#endif

// MARK: - Emoji input

/// A one-emoji text field with quick picks. Anything typed collapses to its first emoji;
/// non-emoji input is discarded.
struct EmojiField: View {
    @Environment(\.palette) private var palette

    let suggestions: [String]
    @Binding var emoji: String?

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        TextField("Type any emoji", text: Binding(
            get: { emoji ?? "" },
            set: { emoji = $0.firstEmoji }
        ))
        .font(.title2)

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(suggestions, id: \.self) { candidate in
                Button {
                    emoji = candidate
                    Haptics.selection()
                } label: {
                    Text(candidate)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(emoji == candidate
                                      ? AnyShapeStyle(palette.accent.opacity(0.28))
                                      : AnyShapeStyle(palette.textSecondary.opacity(0.08)))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Emoji \(candidate)")
                .accessibilityAddTraits(emoji == candidate ? .isSelected : [])
            }
        }
        .padding(.vertical, 2)
    }
}
