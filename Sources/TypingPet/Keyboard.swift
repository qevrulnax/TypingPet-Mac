import AppKit
import CoreGraphics

final class Keyboard {
    var onKey: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    var running: Bool { tap != nil }
    @discardableResult func start(request: Bool = false) -> Bool {
        stop()
        if request { _ = CGRequestListenEventAccess() }
        guard CGPreflightListenEventAccess() else { return false }
        let callback: CGEventTapCallBack = { _, type, _, context in
            guard let context else { return nil }
            let monitor = Unmanaged<Keyboard>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            } else if type == .keyDown { monitor.onKey?() }
            // Listen-only: never modify, suppress, read characters, or store keystrokes.
            return nil
        }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue), callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { return false }
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }
    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil; tap = nil
    }
    deinit { stop() }
}
