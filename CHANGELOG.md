# Changelog

Every released version, newest first.

Versions are date stamped: `yyyy.MMdd.<major>.<minor>`, so `2026.903.1.2` is the second release
of 3 September 2026. The day is one number because a VSIX version holds exactly four of them.

---

## 2026.903.1.9

**Added**

- **Jarvis > Licence...** shows the terms, read from the LICENSE.txt inside the installed
  extension rather than from a copy in the code, so the menu can never say something the package
  does not. It leads with the two lines that matter: free to use, including at work; not to be
  sold.

## 2026.903.1.8

**Changed**

- **The licence is no longer MIT.** It is still free to use for anything, including commercially,
  and free to pass on unmodified — but it may no longer be sold, charged for, or included in
  anything that is sold. The no-warranty terms are unchanged, and the terms are summarised in the
  README as well as in `LICENSE.txt`.

## 2026.903.1.7

**Changed**

- The package is now **Jarvis SSMS Extension**. The name says what it is and where it runs; the
  menu, the Options page and the output pane are still just **Jarvis**.

## 2026.903.1.6

**Supersedes 2026.903.1.5**, whose `install.ps1` could not install anything. If you downloaded
that one, take this instead.

**Fixed**

- `install.ps1` could not find the package when run from the release repository. It looked for a
  `.vsix` beside itself, but a release keeps packages under `releases/<version>/` so older ones
  stay downloadable — so a fresh download reported "No .vsix found". It now searches there too
  and picks the newest, ordered by parsed version rather than by name.

## 2026.903.1.4

**Changed**

- **About** is a real window instead of a message box. The shell's box silently truncates a long
  body, so everything below the first heading was being cut off with no sign it was missing.
- About now reports **what Jarvis is doing right now** — active style, terminators, format on
  save, IntelliSense, the connected database, what the catalogue holds, whether the history is
  recording — rather than reciting features. Values are selectable and there is a **Copy
  details** button, because that is what belongs in a bug report.
- One version shown, not two. The build stamp said the same thing as the date stamped version.

## 2026.903.1.2

**Added**

- The **snippet file** and the **query history file** each get a **...** button in Options,
  opening a file dialog on wherever the setting currently resolves to.

**Changed**

- The extension is now **Jarvis for SSMS** rather than Jarvis SQL Formatter — it has not been
  only a formatter for some time. The Options page, the output pane and the status messages all
  say Jarvis.
- Snippets moved from `%APPDATA%\Jarvis SQL Formatter\` to `%APPDATA%\Jarvis\`, beside the query
  history. **An existing snippet file is moved across automatically** the first time Jarvis looks
  for it; it is copied and then the original deleted, so a file that cannot be deleted still
  leaves the snippets readable.

## 2026.903.1.1

**Changed**

- README rewritten for what the product actually is, and corrected where it had drifted: it
  claimed three `sys.*` queries when there are four, and that only Jarvis Gold terminated
  statements when that is now a setting that holds across every style.

## 2026.902.1.8

**Fixed**

- The semicolon on a generated procedure call went on a line of its own. It now goes on the last
  parameter's line, after the value and **before** its comment — where a semicolon after the
  comment would be inside the comment and do nothing at all.

## 2026.902.1.7

**Fixed**

- **Procedure parameters were never written.** Committing a completion reset the session before
  building the call template, which cleared the catalogue it needed, so it silently produced
  nothing every time. Input parameters, OUTPUT declarations and the trailing SELECT all now
  appear as intended.

## 2026.902.1.6

**Added**

- **F12** is now Jarvis's own command with its own key binding. SSMS binds nothing to F12 in a
  query window, so hooking the shell's Go To Definition meant no command was ever dispatched and
  the key did nothing. Also on **Jarvis ▸ IntelliSense ▸ Go To Definition**, and it says on the
  status bar when it declines.

## 2026.902.1.5

**Fixed**

- Switching database left the first completion reporting "Reading `<database>`…" and offering
  nothing, because the catalogue loads on demand. Jarvis now notices the switch when the editor
  takes focus and starts reading straight away.

## 2026.902.1.4

**Changed**

- **Refresh Column Metadata** is now **Refresh Metadata** — it re-reads tables, columns, keys,
  procedures and parameters, not just columns — and has a shortcut, **Ctrl+K, Ctrl+R**.

## 2026.902.1.3

**Fixed**

- The completion list stayed open when switching between query tabs. Switching tabs does not
  deactivate SSMS, so nothing else noticed; the list now closes when its editor loses focus, and
  when the caret moves to another line.

## 2026.902.1.2

**Fixed**

- The completion list could appear outside SSMS, over the desktop, and followed you onto another
  virtual desktop. It was a top level window with no owner. SSMS now owns it, and it closes when
  SSMS stops being the active application.

## 2026.902.1.1

**Added**

- **Date stamped versions.** `publish.ps1 -Date -Major 1` produces `yyyy.MMdd.<major>.<minor>`
  and works the minor out from what is already published.
- **Terminate statements with ;** in Options, on by default, holding whichever style is picked.

## 1.5.0

**Added**

- **Choosing a procedure writes the call**, not just the name: every parameter on its own line as
  a named argument, types shown, optional ones marked. **OUTPUT parameters** bring their `DECLARE`
  lines above and a `SELECT` below, since a call that omits the keyword fails silently and one
  naming an undeclared variable does not run at all.
- **F12** opens the definition of the procedure, function, view or trigger under the caret.
- Routine parameters are read into the catalogue, from a fourth `sys.*` query.

## 1.4.1

**Fixed**

- The IntelliSense list appeared far from the caret on a scaled display: the DPI came from
  `Application.Current.MainWindow`, which is often null in SSMS, and the fallback was wrong by
  exactly the scale factor. It now comes from the editor's own monitor, and the list is clamped
  to that monitor.
- **Snippets now win on Tab.** With the list open, `ssf` + Tab committed whatever the list had
  highlighted instead of expanding the snippet.

## 1.4.0

**Added**

- The **snippet file** can be moved — a shared folder for a team, or a repository.

**Changed**

- Options renamed from **Jarvis SQL Formatter** to **Jarvis**.

## 1.3.6

**Changed**

- The query history window opens about twice as tall, with wider columns.

## 1.3.5

**Fixed**

- **Open in editor** failed with `E_FAIL`. It called one command name that SSMS may not have and
  that is disabled while focus is in a tool window. It now hands focus back first, tries several
  names, and falls back to opening the query as a file, then the clipboard. It also verifies a
  new window actually opened before writing, so the query can never land in the middle of the
  script you already had open.
- Choosing a query now closes the history window.

## 1.3.4

**Added**

- The **query history file** can be moved, and falls back to the default when the path cannot be
  written to rather than silently dropping every query.

**Fixed**

- The history window failed to open at all with "Catastrophic failure": a tool window's content
  has to exist before the shell builds the frame around it.

## 1.3.3

**Fixed**

- The **Query** column in the history was always blank — it bound to a method rather than a
  property, which WPF renders as an empty cell without complaining.
- An empty history now says which kind of empty it is, rather than looking broken.

## 1.3.2

**Fixed**

- Splitting an export by size produced wildly uneven files — a 464 KB file next to a 41 MB one —
  because each file was planned by splitting the whole result set again, which moved every
  boundary. Files are now planned forward from where the export has reached, and each one is
  measured after it is written: anything over the limit is written again smaller, so the maximum
  is a real maximum.

**Changed**

- The size split is a single **maximum** rather than a minimum and maximum.

## 1.3.1

**Added**

- A long export runs on a **background thread** with a **progress window** and a **Cancel**
  button, instead of freezing SSMS.

**Fixed**

- `.xlsx` files came out about a fifth of the size asked for, because the split was planned from
  the uncompressed size and a workbook is a compressed zip.

## 1.3.0

**Added**

- **Every export asks how to split it**, because the answer depends on the result set: one file,
  a number of rows, or a maximum size. It shows the total size before you choose and what your
  choice will produce.

## 1.2.1

**Added**

- Exports split into files of 500,000 rows by default, for Excel and CSV alike. Every file
  carries the header row, and a worksheet is capped at Excel's own 1,048,575 row limit.

## 1.2.0

**Added**

- **Query history.** Every query you run is recorded with the server, database and time, and
  searchable by text, server and date range.

## 1.1.3

**Fixed**

- Exporting a large result set failed with "capacity was less than the current size". Both
  writers built the whole file as one string first; they now stream, so there is no size ceiling
  and half the peak memory.
- A trailing dot in the suggested file name, which Windows silently drops.

## 1.1.0

**Added**

- **Export the results grid** to a real `.xlsx` workbook or to pipe delimited CSV, from the
  grid's right click menu or **Jarvis ▸ Results**. Headers included, numbers written as numbers,
  and anything that only looks like a number — `007`, a leading zero phone number — kept as text.
