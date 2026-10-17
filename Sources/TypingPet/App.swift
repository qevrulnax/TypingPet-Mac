import AppKit
import UniformTypeIdentifiers

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = Store()
    let keyboard = Keyboard()
    var panel: PetPanel!
    var pet: PetView!
    var status: NSStatusItem!
    var timer: Timer?
    var reaction = Reaction()
    var lastLeft = false
    var paused = false
    var lastPhase: ReactionPhase = .idle
    var screenObserver: NSObjectProtocol?
    var activationObserver: NSObjectProtocol?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let size = store.preferences.size
        panel = PetPanel(contentRect: NSRect(x: 0, y: 0, width: size, height: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        pet = PetView(frame: panel.contentView!.bounds)
        panel.contentView = pet
        pet.menuProvider = { [weak self] in self?.makeMenu() ?? NSMenu() }
        pet.moved = { [weak self] in self?.constrain(); self?.savePosition() }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "TypingPet")
        keyboard.onKey = { [weak self] in self?.key() }
        _ = keyboard.start()
        activationObserver = NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }; _ = self.keyboard.start(); self.refreshMenu()
        }
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.constrain() }
        applySettings()
        if let x = store.preferences.x, let y = store.preferences.y { panel.setFrameOrigin(NSPoint(x: x, y: y)); constrain() } else { resetPosition() }
        render(active: false)
        panel.orderFrontRegardless()
        refreshMenu()
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            let phase: ReactionPhase = self.paused ? .idle : self.reaction.phase(at: now)
            if phase != self.lastPhase { self.render(phase: phase) }
            if case .pose = phase {
                let offset = CGFloat(3 + sin(now * 4) * 2)
                self.pet.frame = NSRect(x: 0, y: offset, width: self.panel.frame.width, height: self.panel.frame.height - 6)
            }
        }
        if !UserDefaults.standard.bool(forKey: "onboarded") {
            UserDefaults.standard.set(true, forKey: "onboarded")
            DispatchQueue.main.async { self.help() }
        }
    }
    func key() {
        guard !paused else { return }
        lastLeft = reaction.key(at: ProcessInfo.processInfo.systemUptime)
        render(active: true)
    }
    func render(active: Bool) {
        render(phase: active ? .typing : .idle)
    }
    func render(phase: ReactionPhase) {
        lastPhase = phase
        let active = phase == .typing
        let c = store.preferences.characters.first { $0.id == store.preferences.selected }
        let relative: String?
        switch phase {
        case .typing: relative = (lastLeft ? c?.left : c?.right) ?? c?.idle
        case .pose(let index):
            if let poses = c?.afterTyping, !poses.isEmpty { relative = poses[index % poses.count] }
            else { relative = c?.idle }
        case .idle: relative = c?.idle
        }
        let path = relative.map { store.root.appendingPathComponent($0).path }
        pet.show(path: path, active: active, left: lastLeft)
        // Move content within the window, never alter the saved desktop position.
        let inset: CGFloat = active ? 6 : 0
        pet.frame = NSRect(x: 0, y: inset, width: panel.frame.width, height: panel.frame.height - inset)
    }
    func save() {
        do { try store.save() } catch { alert("保存失败", error.localizedDescription) }
    }
    func savePosition() { store.preferences.x = panel.frame.minX; store.preferences.y = panel.frame.minY; save() }
    func constrain() {
        let screens = NSScreen.screens.map(\.visibleFrame)
        guard !screens.isEmpty else { return }
        let current = panel.frame
        let screen = screens.first { $0.intersects(current) } ?? screens[0]
        let x = min(max(current.minX, screen.minX), screen.maxX - current.width)
        let y = min(max(current.minY, screen.minY), screen.maxY - current.height)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    func applySettings() {
        reaction.reset()
        panel.level = store.preferences.topmost ? .floating : .normal
        panel.ignoresMouseEvents = store.preferences.locked
        panel.setContentSize(NSSize(width: store.preferences.size, height: store.preferences.size))
        constrain(); render(active: false)
    }
    func refreshMenu() { status.menu = makeMenu() }
    func item(_ title: String, _ action: Selector, tag: Int = 0, checked: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self; item.tag = tag; item.state = checked ? .on : .off
        return item
    }
    func makeMenu() -> NSMenu {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: keyboard.running ? "键盘互动已启用" : "键盘互动未授权", action: nil, keyEquivalent: ""))
        m.addItem(item("授权／重新连接键盘互动…", #selector(authorize)))
        m.addItem(item("暂停互动", #selector(togglePause), checked: paused))
        m.addItem(item(panel.isVisible ? "隐藏宠物" : "显示宠物", #selector(toggleVisible)))
        m.addItem(.separator())
        let chars = NSMenu()
        chars.addItem(item("内置小猫", #selector(selectCharacter), tag: -1, checked: store.preferences.selected == nil))
        for (i, c) in store.preferences.characters.enumerated() { chars.addItem(item(c.name, #selector(selectCharacter), tag: i, checked: c.id == store.preferences.selected)) }
        let characterItem = NSMenuItem(title: "切换角色", action: nil, keyEquivalent: ""); characterItem.submenu = chars; m.addItem(characterItem)
        m.addItem(item("一键导入素材文件夹…", #selector(importFolder)))
        m.addItem(item("导入角色图片／动画…", #selector(importCharacter)))
        m.addItem(item("设置左手按键动画…", #selector(importLeft)))
        m.addItem(item("设置右手按键动画…", #selector(importRight)))
        m.addItem(item("设置停笔后动作…", #selector(importAfterTyping)))
        let sizes = NSMenu()
        for s in [100, 140, 180, 240, 320, 480] { sizes.addItem(item("\(s) 像素", #selector(resize), tag: s, checked: Int(store.preferences.size) == s)) }
        let sizeItem = NSMenuItem(title: "宠物尺寸", action: nil, keyEquivalent: ""); sizeItem.submenu = sizes; m.addItem(sizeItem)
        m.addItem(item("始终置顶", #selector(toggleTop), checked: store.preferences.topmost))
        m.addItem(item("锁定位置（鼠标穿透）", #selector(toggleLock), checked: store.preferences.locked))
        m.addItem(item("重置位置", #selector(resetPosition)))
        m.addItem(.separator())
        m.addItem(item("使用说明与隐私…", #selector(help)))
        m.addItem(item("退出 TypingPet", #selector(quit)))
        return m
    }
    @objc func authorize() {
        if !keyboard.start(request: true) {
            alert("需要输入监控权限", "请在系统设置 → 隐私与安全性 → 输入监控中允许 TypingPet，然后退出并重新打开应用。密码框、安全输入模式、登录界面可能不会触发互动。")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") { NSWorkspace.shared.open(url) }
        }
        refreshMenu()
    }
    @objc func togglePause() { paused.toggle(); reaction.reset(); render(active: false); refreshMenu() }
    @objc func toggleVisible() { if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }; refreshMenu() }
    @objc func toggleTop() { store.preferences.topmost.toggle(); applySettings(); save(); refreshMenu() }
    @objc func toggleLock() { store.preferences.locked.toggle(); applySettings(); save(); refreshMenu() }
    @objc func resize(_ sender: NSMenuItem) { store.preferences.size = Double(sender.tag); applySettings(); savePosition(); refreshMenu() }
    @objc func selectCharacter(_ sender: NSMenuItem) {
        store.preferences.selected = sender.tag < 0 ? nil : store.preferences.characters[sender.tag].id
        reaction.reset()
        render(active: false); save(); refreshMenu()
    }
    @objc func resetPosition() {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        panel.setFrameOrigin(NSPoint(x: screen.maxX - panel.frame.width - 30, y: screen.minY + 25)); savePosition()
    }
    @objc func importFolder() {
        NSApp.activate(ignoringOtherApps: true)
        let picker = NSOpenPanel()
        picker.title = "选择解压后的素材文件夹（含 basic、Left、Right 等图片）"
        picker.canChooseFiles = false; picker.canChooseDirectories = true
        picker.allowsMultipleSelection = false
        guard picker.runModal() == .OK, let folder = picker.url else { return }
        var staged: [URL] = []
        let previous = store.preferences
        do {
            let plan = try FolderPlan(files: FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isRegularFileKey]))
            var copied: [URL: String] = [:]
            for url in plan.files {
                guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { throw FolderImportError.invalidImage }
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                guard let size = attrs[.size] as? NSNumber, size.intValue < 30_000_000 else { throw FolderImportError.invalidImage }
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                guard NSImage(data: data) != nil else { throw FolderImportError.invalidImage }
                let name = UUID().uuidString + "." + url.pathExtension.lowercased()
                let target = store.root.appendingPathComponent(name)
                try data.write(to: target, options: .atomic)
                staged.append(target); copied[url] = name
            }
            let c = Character(id: UUID(), name: folder.lastPathComponent + " · 打字", idle: copied[plan.idle]!, left: plan.left.flatMap { copied[$0] }, right: plan.right.flatMap { copied[$0] }, afterTyping: plan.poses.isEmpty ? nil : plan.poses.compactMap { copied[$0] })
            store.preferences.characters.append(c)
            store.preferences.selected = c.id
            try store.save()
            reaction.reset(); render(active: false); refreshMenu()
            alert("导入成功", "已配好待机、左右手与可用的停笔动作。到其他应用打字试试吧！")
        } catch {
            store.preferences = previous
            for url in staged { try? FileManager.default.removeItem(at: url) }
            alert("文件夹导入失败", error.localizedDescription)
        }
    }
    @objc func importCharacter() { importImage(slot: 0) }
    @objc func importLeft() { importImage(slot: 1) }
    @objc func importRight() { importImage(slot: 2) }
    @objc func importAfterTyping() { importImage(slot: 3) }
    func importImage(slot: Int) {
        if slot != 0 && store.preferences.selected == nil { alert("请先导入角色", "内置小猫无需图片。先导入一张待机图片或动画，再设置左右手动画。"); return }
        NSApp.activate(ignoringOtherApps: true)
        let picker = NSOpenPanel()
        picker.title = "选择 GIF、APNG、WebP 或静态图片"
        picker.allowedContentTypes = ["png", "apng", "gif", "webp", "jpg", "jpeg"].compactMap { UTType(filenameExtension: $0) }
        picker.allowsMultipleSelection = false; picker.canChooseDirectories = false
        guard picker.runModal() == .OK, let url = picker.url else { return }
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count < 30_000_000, NSImage(data: data) != nil else { throw NSError(domain: "TypingPet", code: 1, userInfo: [NSLocalizedDescriptionKey: "图片无法解码，或文件超过 30 MB。请换一张有效图片。"] ) }
            let name = UUID().uuidString + "." + url.pathExtension.lowercased()
            try data.write(to: store.root.appendingPathComponent(name), options: .atomic)
            if slot == 0 {
                let c = Character(id: UUID(), name: url.deletingPathExtension().lastPathComponent, idle: name)
                store.preferences.characters.append(c); store.preferences.selected = c.id
            } else if let index = store.preferences.characters.firstIndex(where: { $0.id == store.preferences.selected }) {
                if slot == 1 { store.preferences.characters[index].left = name }
                else if slot == 2 { store.preferences.characters[index].right = name }
                else { store.preferences.characters[index].afterTyping = [name] }
            }
            save(); render(active: false); refreshMenu()
        } catch { alert("导入失败", error.localizedDescription) }
    }
    func alert(_ title: String, _ message: String) { NSApp.activate(ignoringOtherApps: true); let a = NSAlert(); a.messageText = title; a.informativeText = message; a.runModal() }
    @objc func help() {
        alert("欢迎使用 TypingPet for Mac", "点击菜单栏爪印操作。拖动宠物可移动，右键可设置；锁定后从菜单栏解锁。\n\n先授权输入监控，再到其他应用打字。真实键盘按下会交替触发左右手。配置停笔动作后，停止输入约半秒会自动做动作，约 1.6 秒后回到待机。再次打字立即中断动作。\n\n公开版不附带第三方角色图片。选择“一键导入素材文件夹”可自动配好角色；导入 GIF / APNG / WebP 可播放动画；可分别设置待机、左手、右手。透明效果取决于素材本身是否透明。\n\n本应用不读取字符内容、不保存按键、不联网传输。素材复制到本机应用支持目录，原文件可移走。")
    }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); keyboard.stop(); savePosition() }
}
@main
struct TypingPetMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
