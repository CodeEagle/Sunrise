#if canImport(UIKit)
import UIKit

/// Loads a single PNG arranged as an N×M grid of frames and slices it
/// into individual `UIImage` frames suitable for `UIImage.animatedImage`.
///
/// One codex call → one spritesheet → consistent visual style across all
/// frames (every frame is painted in the same gen pass, so character /
/// palette / texture stay locked). The runtime then plays the slices via
/// `UIImageView.animationImages` for a smooth loop. Falls back to the
/// static base icon when no spritesheet is bundled.
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

    /// Slices `name` into `grid.columns * grid.rows` `UIImage` frames in
    /// row-major reading order (top-left → top-right → next row…).
    /// Frames are cached per-name so repeated lookups (e.g. one icon per
    /// row in the daily list) don't re-decode the source PNG.
    /// Returns nil when the asset is missing or the dimensions don't
    /// divide evenly.
    public static func loadFrames(
        named name: String,
        grid: Grid,
        in bundle: Bundle = .main
    ) -> [UIImage]? {
        Cache.shared.frames(named: name, grid: grid, bundle: bundle)
    }

    private final class Cache: @unchecked Sendable {
        static let shared = Cache()
        private let lock = NSLock()
        private var store: [String: [UIImage]] = [:]

        func frames(named name: String, grid: Grid, bundle: Bundle) -> [UIImage]? {
            lock.lock()
            defer { lock.unlock() }
            if let cached = store[name] { return cached }
            let frames = Self.slice(name: name, grid: grid, bundle: bundle)
            if let frames {
                store[name] = frames
            }
            return frames
        }

        private static func slice(name: String, grid: Grid, bundle: Bundle) -> [UIImage]? {
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
                    if let cropped = cg.cropping(to: rect) {
                        frames.append(UIImage(
                            cgImage: cropped,
                            scale: sheet?.scale ?? 1,
                            orientation: .up
                        ))
                    }
                }
            }
            return frames.isEmpty ? nil : frames
        }
    }
}
#endif
