# The desktop shell

A native macOS window around the hosted app. About 200 lines of Swift, ~1MB built,
and **no toolchain to install** — it compiles with the Xcode command line tools
macOS already has.

```bash
./build.sh            # builds into ./dist
./build.sh --install  # builds, then puts it in /Applications
```

Then drag it to the Dock. First launch may need right-click → Open, because it's
ad-hoc signed; after that it opens normally.

---

## Why it exists

Two reasons, and the second turned out to matter more.

**Opening files.** A web page cannot open a document in Word or PowerPoint. Not
a limitation of this app — `file://` links are blocked from an https page, and
the File System Access API deliberately never reveals where a file is on disk.
The shell can, so a lesson can point at the twenty documents in its folder and
you click one instead of hunting for it.

**Saving stops being hard.** In the browser, keeping plans in a real folder needs
the File System Access API, a directory handle persisted in IndexedDB, permission
re-granted whenever the browser feels like it, a Reconnect button for when that
lapses, and a whole separate "Back up" path for browsers that can't do any of it.
Here it's a path and a write.

## How it loads

The window opens `https://ben0sb0rne.github.io/lesson-planner/` — the same hosted
app. **Every push updates it.** There is no bundled copy to go stale, no rebuild
to remember, and no way for the Mac and the PC to drift apart. The service worker
the site already ships keeps it working offline.

Point it somewhere else while developing:

```bash
LESSON_PLANNER_URL="http://localhost:8000/" "dist/Lesson Planner.app/Contents/MacOS/Lesson Planner"
```

## The bridge

`index.html` is unchanged and still works in any browser — it feature-detects
`window.planner` and falls back to the File System Access API when it isn't there.
The shell adds only what a page isn't allowed to do:

| | |
|---|---|
| `open(path)` | the real file, in its real application |
| `reveal(path)` | show it in Finder |
| `chooseFolder()` · `chooseFile()` | a native picker, returning a path |
| `listFolder(path)` | name, path, extension, size, modified |
| `readFile` · `writeFile` · `remove` · `exists` | plain file access |

`writeFile` writes atomically and creates missing parent folders, which is what
lets the dated backups work.

## The one thing that changes

WKWebView is Safari's engine, so the File System Access API isn't there. Verified
everything else this app leans on **does** work: `execCommand` lists and
`formatBlock` (caret preserved), `queryCommandState`, CSS subgrid, `color-mix`,
`-webkit-line-clamp`, `:has`, drag-and-drop with `DataTransfer` round-tripping,
`showPicker` on date inputs, IndexedDB, service workers, and MathML rendering a
real stacked fraction.

So the storage layer isn't forked. `shellDir()` in `index.html` presents a path as
something shaped like a `FileSystemDirectoryHandle`, and the existing save code —
atomic writes, dated backups, revision conflict detection — runs unchanged on top
of it.

## Not done yet

- The Windows side. Same idea, different shell.
- Linking a lesson to a folder, which is the feature this was built for.
