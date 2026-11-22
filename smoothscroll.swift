// smoothscroll: headless smooth scrolling for mouse wheels on macOS.
//
// Intercepts notched mouse-wheel events, swallows them, and replays the distance
// as a stream of small pixel-scroll events with exponential easing, so a wheel
// glides like a trackpad. Trackpad / Magic Mouse gestures (which carry a scroll or
// momentum phase) pass through untouched, as do scrolls with Shift/Cmd/Ctrl/Option held.
//
// Usage: smoothscroll [--speed PX_PER_LINE] [--smooth SECONDS] [--debug]
//   --speed   pixels scrolled per wheel line (default 40). Higher = faster.
//   --smooth  easing time constant in seconds (default 0.12). Higher = longer glide.
//   --debug   log every incoming scroll event's fields.

import ApplicationServices
import Foundation

var pixelsPerLine = 40.0
var timeConstant = 0.12
var debug = false
setvbuf(stdout, nil, _IOLBF, 0)  // line-buffer so the launchd log updates immediately

do {
    var args = CommandLine.arguments.dropFirst().makeIterator()
    while let a = args.next() {
        switch a {
        case "--debug": debug = true
        case "--speed": if let v = args.next().flatMap(Double.init) { pixelsPerLine = v }
        case "--smooth": if let v = args.next().flatMap(Double.init) { timeConstant = max(v, 0.01) }
        case "-h", "--help":
            print("usage: smoothscroll [--speed PX_PER_LINE] [--smooth SECONDS] [--debug]")
            exit(0)
        default:
            FileHandle.standardError.write("unknown argument: \(a)\n".data(using: .utf8)!)
            exit(2)
        }
    }
}

let kMagic: Int64 = 0x534D_5343  // tags our own synthetic events so the tap ignores them

final class Smoother {
    private var remY = 0.0, remX = 0.0     // distance still to scroll (px)
    private var fracY = 0.0, fracX = 0.0   // sub-pixel carry
    private var timer: Timer?
    private var lastTick = 0.0

    func add(dy: Double, dx: Double) {
        // Reversing direction cancels the leftover glide instead of fighting it.
        if dy != 0, remY != 0, (dy > 0) != (remY > 0) { remY = 0; fracY = 0 }
        if dx != 0, remX != 0, (dx > 0) != (remX > 0) { remX = 0; fracX = 0 }
        remY += dy
        remX += dx
        if timer == nil {
            lastTick = CFAbsoluteTimeGetCurrent()
            let t = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
    }

    private func tick() {
        let now = CFAbsoluteTimeGetCurrent()
        let dt = min(now - lastTick, 0.05)
        lastTick = now
        let k = 1 - exp(-dt / timeConstant)

        let my = abs(remY) < 1 ? remY : remY * k
        let mx = abs(remX) < 1 ? remX : remX * k
        remY -= my
        remX -= mx
        fracY += my
        fracX += mx
        let iy = Int32(fracY.rounded(.towardZero))
        let ix = Int32(fracX.rounded(.towardZero))
        fracY -= Double(iy)
        fracX -= Double(ix)

        if iy != 0 || ix != 0 { post(dy: iy, dx: ix) }
        if remY == 0 && remX == 0 {
            timer?.invalidate()
            timer = nil
            fracY = 0
            fracX = 0
        }
    }

    private func post(dy: Int32, dx: Int32) {
        guard let e = CGEvent(scrollWheelEvent2Source: nil, units: .pixel,
                              wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0) else { return }
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        e.setIntegerValueField(.eventSourceUserData, value: kMagic)
        e.post(tap: .cghidEventTap)
    }
}

let smoother = Smoother()
var tap: CFMachPort?
let passThroughModifiers: CGEventFlags = [.maskShift, .maskCommand, .maskControl, .maskAlternate]

let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    if debug, type == .scrollWheel, event.getIntegerValueField(.eventSourceUserData) != kMagic {
        print("scroll continuous=\(event.getIntegerValueField(.scrollWheelEventIsContinuous))",
              "line=\(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))",
              "fixed=\(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1))",
              "point=\(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1))",
              "phase=\(event.getIntegerValueField(.scrollWheelEventScrollPhase))",
              "momentum=\(event.getIntegerValueField(.scrollWheelEventMomentumPhase))",
              "srcpid=\(event.getIntegerValueField(.eventSourceUnixProcessID))",
              "flags=\(event.flags.rawValue)")
    }
    guard type == .scrollWheel,
          event.getIntegerValueField(.eventSourceUserData) != kMagic,
          // Trackpads and Magic Mouse always report a gesture/momentum phase. Wheel notches
          // don't, even when Logi Options+ re-posts them flagged as continuous.
          event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
          event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0,
          event.flags.intersection(passThroughModifiers).isEmpty
    else { return Unmanaged.passUnretained(event) }

    let dy = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
    let dx = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
    if dy == 0 && dx == 0 { return Unmanaged.passUnretained(event) }

    if debug { print("  -> smoothed") }
    smoother.add(dy: dy * pixelsPerLine, dx: dx * pixelsPerLine)
    return nil  // swallow the original notched event
}

// An active event tap needs Accessibility permission. A running process doesn't see a
// grant made after it started, so exit and let launchd relaunch us (every ~10s) instead.
let promptKey = "AXTrustedCheckOptionPrompt" as CFString
if !AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary) {
    FileHandle.standardError.write("""
        smoothscroll: no Accessibility permission yet; will retry.
        Enable it in System Settings > Privacy & Security > Accessibility for:
        \(CommandLine.arguments[0])\n
        """.data(using: .utf8)!)
    sleep(10)
    exit(1)
}

let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                options: .defaultTap, eventsOfInterest: mask,
                                callback: callback, userInfo: nil) else {
    FileHandle.standardError.write("smoothscroll: failed to create event tap\n".data(using: .utf8)!)
    exit(1)
}
tap = t
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
CGEvent.tapEnable(tap: t, enable: true)
print("smoothscroll: running (speed \(pixelsPerLine) px/line, smooth \(timeConstant)s)")
CFRunLoopRun()
