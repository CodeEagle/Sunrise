#if canImport(UIKit)
import UIKit

/// Loads a single PNG arranged as an N×M grid of frames, slices each
/// frame, and pre-downsamples them to a target edge size before handing
/// the result to `UIImageView.animationImages`.
///
/// Why pre-downsample: the source spritesheet is 2048×2048 (16 frames at
/// 512×512). Display sites are 32–44pt — keeping frames at the source
/// resolution forces the GPU to scale a 1MB texture every tick, which
/// reads as choppy on lower-end devices. Re-rendering each frame into
/// a 96-128pt canvas at first load trades a one-shot decode cost for
/// silky-smooth playback afterwards.
///
/// Result frames stay cached per `(name, targetEdge)` so the same icon
/// reused across the day strip + daily list doesn't decode twice.
public enum WeatherIconSpritesheet {
    public struct Grid: Sendable, Hashable {
        public let columns: Int
        public let rows: Int
        public init(columns: Int, rows: Int) {
            self.columns = columns
            self.rows = rows
        }
        public var frameCount: Int { columns * rows }
    }

    /// Slices `name` into `grid.frameCount` frames downsampled to
    /// `targetEdge` × `targetEdge` points (rendered at the screen scale
    /// for crispness). Returns nil when the asset is missing or the
    /// source dimensions don't divide evenly.
    public static func loadFrames(
        named name: String,
        grid: Grid,
        targetEdge: CGFloat = 128,
        in bundle: Bundle = .main
    ) -> [UIImage]? {
        Cache.shared.frames(named: name, grid: grid, targetEdge: targetEdge, bundle: bundle)
    }

    private final class Cache: @unchecked Sendable {
        static let shared = Cache()
        private let lock = NSLock()
        private var store: [String: [UIImage]] = [:]

        func frames(named name: String, grid: Grid, targetEdge: CGFloat, bundle: Bundle) -> [UIImage]? {
            let key = "\(name)#\(Int(targetEdge.rounded()))"
            lock.lock()
            defer { lock.unlock() }
            if let cached = store[key] { return cached }
            let frames = Self.slice(name: name, grid: grid, targetEdge: targetEdge, bundle: bundle)
            if let frames {
                store[key] = frames
            }
            return frames
        }

        private static func slice(name: String, grid: Grid, targetEdge: CGFloat, bundle: Bundle) -> [UIImage]? {
            let sheet: UIImage? = {
                if let asset = UIImage(named: name, in: bundle, with: nil) { return asset }
                if let path = bundle.path(forResource: name, ofType: "png") {
                    return UIImage(contentsOfFile: path)
                }
                return nil
            }()
            guard let cg = sheet?.cgImage else { return nil }
            let frameW = cg.width / grid.columns
            let frameH = cg.height / grid.rows
            guard frameW > 0, frameH > 0 else { return nil }

            let renderSize = CGSize(width: targetEdge, height: targetEdge)
            let format = UIGraphicsImageRendererFormat.default()
            format.opaque = false
            // Use the screen scale so the resampled image stays crisp on
            // 2x / 3x displays without ballooning memory back to 512px.
            let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

            var frames: [UIImage] = []
            frames.reserveCapacity(grid.frameCount)
            for row in 0..<grid.rows {
                for col in 0..<grid.columns {
                    let rect = CGRect(
                        x: col * frameW,
                        y: row * frameH,
                        width: frameW,
                        height: frameH
                    )
                    guard let cropped = cg.cropping(to: rect) else { continue }
                    let croppedImage = UIImage(cgImage: cropped, scale: 1, orientation: .up)
                    let resized = renderer.image { _ in
                        croppedImage.draw(in: CGRect(origin: .zero, size: renderSize))
                    }
                    frames.append(resized)
                }
            }
            return frames.isEmpty ? nil : frames
        }
    }
}
#endif
