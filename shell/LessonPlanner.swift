// Lesson Planner — a native shell around the hosted app.
//
// The window loads https://ben0sb0rne.github.io/lesson-planner/, so every push
// updates it: there is no bundled copy to go stale and no rebuild to remember.
// The service worker the site already ships keeps it working offline.
//
// All the shell adds is a bridge — the handful of things a web page is not
// allowed to do. Opening a file in its real application is the whole point;
// listing a folder is what turns "twenty documents I have to search" into
// something the lesson can show you.
//
// Build:  ./build.sh

import Cocoa
import WebKit

let APP_URL = ProcessInfo.processInfo.environment["LESSON_PLANNER_URL"]
    ?? "https://ben0sb0rne.github.io/lesson-planner/"

// Injected before the page runs, so index.html can feature-detect the bridge
// and fall back cleanly when it's opened in an ordinary browser.
let BRIDGE_JS = """
window.planner = {
  version: 1,
  platform: 'mac',
  _call(op, args){ return window.webkit.messageHandlers.bridge.postMessage(
    Object.assign({ op }, args || {})); },
  open(path){        return this._call('open', { path }); },
  reveal(path){      return this._call('reveal', { path }); },
  chooseFolder(){    return this._call('chooseFolder'); },
  chooseFile(){      return this._call('chooseFile'); },
  listFolder(path){  return this._call('listFolder', { path }); },
  readFile(path){    return this._call('readFile', { path }); },
  writeFile(path, text){ return this._call('writeFile', { path, text }); },
  remove(path){      return this._call('remove', { path }); },
  exists(path){      return this._call('exists', { path }); },
};
document.documentElement.classList.add('in-shell');
"""

final class Bridge: NSObject, WKScriptMessageHandlerWithReply {
    func userContentController(_ ucc: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? [String: Any],
              let op = body["op"] as? String else {
            return replyHandler(nil, "malformed call")
        }
        let path = (body["path"] as? String) ?? ""

        switch op {
        case "open":
            // The whole reason this shell exists: the real file, in its real app.
            guard !path.isEmpty else { return replyHandler(nil, "no path") }
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else {
                return replyHandler(nil, "not found: \(path)")
            }
            NSWorkspace.shared.open(url)
            replyHandler(true, nil)

        case "reveal":
            guard FileManager.default.fileExists(atPath: path) else {
                return replyHandler(nil, "not found: \(path)")
            }
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            replyHandler(true, nil)

        case "chooseFolder", "chooseFile":
            let panel = NSOpenPanel()
            panel.canChooseDirectories = (op == "chooseFolder")
            panel.canChooseFiles = (op == "chooseFile")
            panel.allowsMultipleSelection = false
            panel.prompt = "Choose"
            panel.begin { r in
                guard r == .OK, let u = panel.url else { return replyHandler(nil, nil) }
                replyHandler(["path": u.path, "name": u.lastPathComponent], nil)
            }

        case "listFolder":
            do {
                let fm = FileManager.default
                let dir = URL(fileURLWithPath: path)
                let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey]
                let items = try fm.contentsOfDirectory(at: dir,
                                includingPropertiesForKeys: keys,
                                options: [.skipsHiddenFiles])
                let out: [[String: Any]] = items.map { u in
                    let v = try? u.resourceValues(forKeys: Set(keys))
                    return [
                        "name": u.lastPathComponent,
                        "path": u.path,
                        "ext":  u.pathExtension.lowercased(),
                        "dir":  v?.isDirectory ?? false,
                        "size": v?.fileSize ?? 0,
                        "modified": (v?.contentModificationDate?.timeIntervalSince1970 ?? 0) * 1000,
                    ]
                }
                replyHandler(out, nil)
            } catch {
                replyHandler(nil, "cannot read \(path): \(error.localizedDescription)")
            }

        case "readFile":
            do { replyHandler(try String(contentsOfFile: path, encoding: .utf8), nil) }
            catch { replyHandler(nil, "cannot read \(path)") }

        case "writeFile":
            guard let text = body["text"] as? String else { return replyHandler(nil, "no text") }
            do {
                // The dated backups live in a subfolder that may not exist yet.
                let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parent,
                        withIntermediateDirectories: true)
                // Same atomic swap the browser's createWritable gave us: write a
                // temporary file and move it into place, so an interrupted save
                // can't leave a half-written planner.json behind.
                try text.write(toFile: path, atomically: true, encoding: .utf8)
                replyHandler(true, nil)
            } catch { replyHandler(nil, "cannot write \(path): \(error.localizedDescription)") }

        case "remove":
            // Only ever called to prune old dated backups.
            do { try FileManager.default.removeItem(atPath: path); replyHandler(true, nil) }
            catch { replyHandler(nil, "cannot remove \(path)") }

        case "exists":
            replyHandler(FileManager.default.fileExists(atPath: path), nil)

        default:
            replyHandler(nil, "unknown op \(op)")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var web: WKWebView!
    let bridge = Bridge()

    func applicationDidFinishLaunching(_ n: Notification) {
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.addScriptMessageHandler(
            bridge, contentWorld: .page, name: "bridge")
        cfg.userContentController.addUserScript(
            WKUserScript(source: BRIDGE_JS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        cfg.websiteDataStore = .default()          // keeps localStorage and IndexedDB

        web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = false
        // Web Inspector, so this can be debugged like any other page.
        if #available(macOS 13.3, *) { web.isInspectable = true }

        let f = NSRect(x: 0, y: 0, width: 1280, height: 860)
        window = NSWindow(contentRect: f,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Lesson Planner"
        window.setFrameAutosaveName("LessonPlannerWindow")
        window.contentView = web
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        web.load(URLRequest(url: URL(string: APP_URL)!))
        buildMenu()
    }

    // Links to anywhere other than the app itself belong in the real browser.
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction,
                 decisionHandler d: @escaping (WKNavigationActionPolicy) -> Void) {
        if a.navigationType == .linkActivated, let u = a.request.url,
           !u.absoluteString.hasPrefix(APP_URL) {
            NSWorkspace.shared.open(u)
            return d(.cancel)
        }
        d(.allow)
    }

    // target="_blank" has no window to open into here; hand it to the browser.
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration,
                 for a: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = a.request.url { NSWorkspace.shared.open(u) }
        return nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // Without an edit menu, ⌘C/⌘V/⌘Z don't reach the web view at all — and this
    // app is mostly typing.
    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Lesson Planner",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Reload", action: #selector(reload), keyEquivalent: "r")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Lesson Planner",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Lesson Planner",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        let items: [(String, Selector, String, NSEvent.ModifierFlags)] = [
            ("Undo",       Selector(("undo:")),       "z", .command),
            ("Redo",       Selector(("redo:")),       "z", [.command, .shift]),
            ("Cut",        #selector(NSText.cut(_:)),      "x", .command),
            ("Copy",       #selector(NSText.copy(_:)),     "c", .command),
            ("Paste",      #selector(NSText.paste(_:)),    "v", .command),
            ("Select All", #selector(NSText.selectAll(_:)),"a", .command),
        ]
        for (t, s, k, m) in items {
            let mi = NSMenuItem(title: t, action: s, keyEquivalent: k)
            mi.keyEquivalentModifierMask = m
            edit.addItem(mi)
        }
        editItem.submenu = edit
        NSApp.mainMenu = main
    }

    @objc func reload() { web.reloadFromOrigin() }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
