import AppKit
import WebKit
import ImageIO

// WebKit's system image decoder plays GIF/APNG/animated WebP with their original timing.
// AppKit owns the window, input, drag and settings; the web view only renders a local image.
final class PetView: NSView {
    private let renderer: WKWebView
    private let overlay = NSView()
    private let imageView = NSImageView()
    var menuProvider: (() -> NSMenu)?
    var moved: (() -> Void)?
    private var current: String?
    private var pressed = false
    private var side = false
    override init(frame: NSRect) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        renderer = WKWebView(frame: .zero, configuration: config)
        super.init(frame: frame)
        renderer.setValue(false, forKey: "drawsBackground")
        renderer.isHidden = true
        renderer.autoresizingMask = [.width, .height]
        renderer.frame = bounds
        addSubview(renderer)
        imageView.frame = bounds
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.isHidden = true
        addSubview(imageView)
        overlay.frame = bounds
        overlay.autoresizingMask = [.width, .height]
        addSubview(overlay)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func hitTest(_ point: NSPoint) -> NSView? { bounds.contains(point) ? self : nil }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
        moved?()
    }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = menuProvider?() { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }
    func show(path: String?, active: Bool, left: Bool) {
        pressed = active; side = left
        needsDisplay = true
        guard path != current else { return }
        current = path
        if let path {
            let url = URL(fileURLWithPath: path)
            let ext = url.pathExtension.lowercased()
            let mime = ["gif":"image/gif", "png":"image/png", "apng":"image/png", "webp":"image/webp", "jpg":"image/jpeg", "jpeg":"image/jpeg"][ext] ?? "image/png"
            guard let data = try? Data(contentsOf: url), data.count < 30_000_000 else { return }
            let source = CGImageSourceCreateWithData(data as CFData, nil)
            let frames = source.map { CGImageSourceGetCount($0) } ?? 1
            if ext != "webp" && frames == 1 {
                renderer.isHidden = true
                imageView.image = NSImage(data: data)
                imageView.isHidden = false
                return
            }
            imageView.isHidden = true
            // No remote URLs, scripts, navigation, or user-provided markup are loaded.
            let html = "<html><head><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'\"><style>html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden}img{width:100%;height:100%;object-fit:contain}</style></head><body><img src='data:\(mime);base64,\(data.base64EncodedString())'></body></html>"
            renderer.loadHTMLString(html, baseURL: nil)
            renderer.isHidden = false
        } else { renderer.isHidden = true; imageView.isHidden = true }
    }
    override func draw(_ dirtyRect: NSRect) {
        guard current == nil else { return }
        // Original vector placeholder: usable before personal artwork is imported.
        let scale = min(bounds.width, bounds.height) / 200
        NSGraphicsContext.saveGraphicsState()
        let t = NSAffineTransform()
        t.scale(by: scale)
        t.concat()
        let lift: CGFloat = pressed ? 9 : 0
        NSColor(calibratedRed: 0.97, green: 0.78, blue: 0.49, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 32, y: 30 + lift, width: 136, height: 125)).fill()
        for x: CGFloat in [39, 129] {
            let ear = NSBezierPath(); ear.move(to: NSPoint(x: x, y: 130 + lift)); ear.line(to: NSPoint(x: x + 4, y: 185 + lift)); ear.line(to: NSPoint(x: x + 35, y: 145 + lift)); ear.close(); ear.fill()
        }
        NSColor.brown.setFill()
        for x: CGFloat in [72, 119] { NSBezierPath(ovalIn: NSRect(x: x, y: 104 + lift, width: 9, height: 13)).fill() }
        NSBezierPath(ovalIn: NSRect(x: 95, y: 87 + lift, width: 10, height: 7)).fill()
        NSColor(calibratedRed: 0.91, green: 0.58, blue: 0.35, alpha: 1).setFill()
        for (index, x) in [CGFloat(52), CGFloat(119)].enumerated() {
            let raised = pressed && (side == (index == 0))
            NSBezierPath(ovalIn: NSRect(x: x, y: raised ? 65 : 30, width: 30, height: 26)).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}
