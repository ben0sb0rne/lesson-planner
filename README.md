# Lesson Planner

A lesson planner for teachers who got tired of a spreadsheet where inserting one day meant
hand-shifting every cell after it.

Day, week and month views. One tab per class, plus an all-classes view. Your own rows per class.
Drag a day somewhere else and everything after it moves with it.

**One file, no build step, no dependencies.** `index.html` is the whole app — you can email it to
a colleague and it works.

---

## The idea it's built on

**A lesson has no date. It has a position in a list.**

Each class owns an ordered list of lessons. Separately it has the weekdays it meets. The app
generates the dates that class meets — weekdays, minus holidays, minus one-off cancellations —
and then lays lesson 1 on meeting 1, lesson 2 on meeting 2, and so on.

So inserting a day of practice is a one-line array splice, and everything after it re-lands on
later dates by itself. Deleting a day closes the gap the same way. A snow day shortens the
meeting list, which shifts every class forward by one of *its own* meetings — the right amount
for each, even though they meet on different days.

The spreadsheet pain came from storing lessons *by date*. Store them *in order* and it goes away.

One consequence, accepted on purpose: shifting moves **everything** after it, quizzes included.
There's no pinning. If a date matters, change the lessons instead.

---

## Using it

| | |
|---|---|
| Drag a day **between** two others | Inserts it there; everything after shifts forward one meeting |
| Drag a day **onto** another | Swaps them; nothing else moves |
| Right-click a day | Insert, swap, duplicate, clear, remove, mark No Class, copy to another class |
| Shift-click day headers | Selects a run, then tag them all at once |
| `⌘K` | Search every class |
| `⌘Z` / `⌘⇧Z` | Undo / redo — a whole ripple is one press |
| `Tab` | Next box down the day, then on to the next day |
| `⌥←` `⌥→` | Same box, previous / next day |

**Clear day** wipes the plan but keeps the meeting. **Remove day** deletes the meeting and closes
the gap. **No Class** drops that one date for that one class and ripples it forward, like a
private holiday. They're three different things and never share a button.

---

## Where your plans live

By default, inside the browser — which is one "clear browsing data" away from gone.

Open **⋯ → Where plans are saved…** and pick a folder, ideally inside OneDrive or Dropbox. From
then on it writes there automatically:

```
Your folder/
  planner.json           the real file
  plans-readable.json    a flattened copy, for handing to an AI
  backups/               one dated snapshot a day, last 30 kept
```

Two computers stay in step through the sync folder. Saves stamp a revision and a machine name; if
the file on disk looks older than your last save here, the app stops and asks rather than
merging. It never merges silently.

Folder saving needs Chrome or Edge. Safari and Firefox fall back to browser storage and say so —
use **Save a backup file** regularly there.

---

## Sharing what you've planned

- **⋯ → Export to Excel…** — pick dates and classes, get a formatted `.xlsx`. One sheet per class,
  days across, your rows down the side, tags coloured. Optionally include the days a class doesn't
  meet, so a reader sees why there's a gap.
- **⋯ → Export for AI…** — a flattened JSON copy with real dates, class and row names, plain text,
  and a short briefing that teaches the assistant how the schedule works *before* it advises you.
  Copy it straight into a chat.
- **⋯ → Save a backup file** — everything, as JSON, for keeping or moving.

---

## Running it

**Just open it.** Double-click `index.html`.

**Or host it,** which gets you an installable app with its own icon, and makes folder saving
reliable:

```bash
git push -u origin main
```

then in the repo: **Settings → Pages → Source: `main`, folder `/ (root)`**. A minute later it's at
`https://<you>.github.io/<repo>/`. Open it in Chrome and use the install button in the address
bar — it lands in the Dock with the icon and no browser chrome, and works offline.

Hosting publishes *the app*, not your plans. Lesson content never leaves your browser and the
folder you chose; there is no server side to this.

---

## Notes

- `docs/PLANNING.md` — why it's built this way, the data model, the storage design
- `docs/ROADMAP.md` — what shipped, what's deliberately left out, what's next
- Rich text is `contenteditable` and `document.execCommand`. Deprecated, works everywhere, and
  paste is stripped back to the tags the toolbar makes so Word can't inject styling.
- The `.xlsx` writer is hand-rolled — a store-only ZIP with hand-computed CRC-32 plus minimal
  OOXML, about 250 lines, so there's no library to keep up with.
