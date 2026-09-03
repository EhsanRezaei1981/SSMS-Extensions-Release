# Jarvis IntelliSense

## The rule everything else follows

**Exactly one IntelliSense is in charge, and the author picks which.**

`FormatterSettings.JarvisIntelliSense` is that choice, and it moves both halves at once:

| switch | Jarvis list | SSMS IntelliSense |
|---|---|---|
| on | opens as you type | switched off by `SsmsIntelliSense` |
| off | opens only on `Ctrl+K, Ctrl+Space` | switched back on |

That is what makes an automatic list safe. Without the second half the two would race on every
keystroke; with it there is never more than one list on screen. `Ctrl+Space` and `Ctrl+J`, SSMS's
own triggers, are untouched either way.

`SsmsIntelliSense` goes at it two ways, because they do different things and neither is enough
on its own:

1. **The setting.** SSMS 21 and later keep it in the shell's unified settings store under
   `languages.sql.intelliSense.enableIntellisense` — a moniker read straight out of SSMS's own
   `SqlStudio.registration.json`. Writing it is what makes the choice stick and what every
   window opened afterwards honours. The store is reached by querying
   `SVsSettingsPersistenceManager` (`{9B164E40-…}`, which has no public interop assembly) and
   calling `TryGetValue<bool>` / `SetValueAsync` by reflection.
2. **The Query menu command.** That takes effect in the window that already has focus, which
   the setting alone does not always do. It is looked up by name through DTE — falling back to
   scanning the whole command set for one named after IntelliSense — and its state read as
   `OLECMDF_LATCHED` through `SUIHostCommandDispatcher`.

Both are reflection and name lookups against things that are not public contracts, so a version
that moves either simply means that route reports nothing and the other one is used. The write
is **read back** before being called a success: reflection that did not throw proves nothing.
If neither works, the toggle says so in the status bar rather than pretending, and opens the
options dialog that holds the switch.

Worth knowing about the command route: **SSMS 22 gives that command no canonical name at all.**
Scanning `RadLangSvc.dll`, `SQLEditors.dll` and the SqlStudio assemblies turns up no
`Query.IntellisenseEnabled` or anything like it. What it does have is a documented shortcut,
so the command is found by its `Ctrl+B, Ctrl+I` binding as well as by name.

### And, regardless, whatever else is open gets closed

The setting is the tidy answer, but it is read when a query window is created, so it does
nothing for one already open — and it is not the only thing that can put a list on screen.
`CompetingCompletion` therefore dismisses any live session through the editor's own brokers,
both the async one the modern editor uses and the older synchronous one, at the moment Jarvis
opens its list **and again on every keystroke while it is open**, since each keystroke passes
through to the editor and is another chance for someone else's list to appear on top.

Two lists on screen is the one outcome nobody wants, and this is the part that does not depend
on a setting being found, written, or noticed.

Three things it is careful about:

- **It only restores what it turned off.** A `_weTurnedItOff` flag means somebody who already
  had SSMS IntelliSense off keeps it off when they switch Jarvis off again.
- **It never toggles blindly.** If the state cannot be read — no query window open, so nothing
  answers the QueryStatus — it does nothing, rather than risk switching IntelliSense *on*.
- **It hands it back on the way out.** `Dispose` restores, so an extension that is no longer
  running never leaves somebody's editor altered.

The toggle belongs to the editor rather than the shell, so it is re-applied as each query window
opens, through `TextViewWatcher.ViewOpened`.

The list is Jarvis's own WPF popup rather than the shell's completion UI. It registers no
`ICompletionSource`, no `IVsCompletionSet` and no completion broker, so it never contends for
ownership of the editor's completion machinery — there is nothing to arbitrate.

Alongside it are the **one-key completions**: cases where the database already holds a single
right answer and there is nothing to choose between, so a list would be ceremony. Those write
straight in. If the catalogue does not settle the question, nothing is written.

## The list

`CompletionListBuilder` builds a `CompletionList` from the caret's context; `CompletionSession`
shows it under the caret. While it is open the session owns the arrow keys, Page Up/Down,
Home/End, Tab, Enter and Escape; typing and Backspace go **through** to the editor first so the
character actually lands, and the list re-filters afterwards. While no session is open,
`SnippetCommandFilter` intercepts nothing but Tab.

### When it opens

`Ctrl+K, Ctrl+Space` always. With the switch on, `CompletionTrigger.ShouldOpen` decides, on
three triggers and no others:

- **a dot** — the answer there is narrow and certain
- **a space after a word that introduces something** — `ON`, `FROM`, `JOIN`, `INTO`, `SET`,
  `VALUES`, `WHERE`, `AND`, `EXEC` and the rest, plus after a comma or an opening bracket. These
  are the places the list already knows the answer, and making somebody ask for it is a step
  too many. Typing `... t2 ON ` should show the predicate, not wait to be invited.
- **the second letter of a word** — late enough not to flash up on a stray key, early enough to
  be useful. Exactly two, not "two or more": past that the author is typing, and a list that
  reappears after every Escape is worse than no list.

A space anywhere else is left alone, which is most of them. After a table name comes an alias,
after `=` comes a value, after `AS` comes a name of the author's choosing — nothing to offer in
any of them.

These rules live in the **engine**, not beside the editor, because they are a judgement about
SQL rather than about windows. That is what makes them testable, and they have the tests that
matter: the cases that must *not* fire.

### One keystroke can end one list and begin another

Typing `o`, `n` opens a list on the second letter. The space that follows arrives while that
list is open, so it goes to the session rather than to the trigger — and the trigger was never
consulted, which is why a space after `ON` did nothing at all for a while.

Two things fix it, and both are needed:

- A character that is **not part of a word** — a space, a comma, a bracket — ends the session
  outright rather than narrowing it. Filtering `Sec_Tb_User` by `Sec_Tb_User ` would empty the
  list by a longer route and leave the caret somewhere the list no longer describes.
- The auto-open check runs on **both** paths out of `Exec`, not only the one where no session
  was open. That is what lets the space close the old list and open the one the new position
  calls for, in a single keystroke.

A dot is treated the same way, and for the same reason: `Sec` is a guess at a name, `Sec.` is a
request for that schema's objects. Closing and reopening gets the right heading rather than a
list narrowed into something that only looks correct.

### What is in it

Objects and columns come from the catalogue — tables, views, stored procedures and functions,
each carrying a `SqlObjectKind`. Procedures are read by a separate query from the columns, since
they have none; the index keys existence off its own object dictionary rather than the column
one, so a procedure resolves by name and honestly reports no columns. Keywords, multi-word
constructs, functions and data types come from `SqlConstructs`. The constructs are the interesting half — offering a bare
`INNER` helps nobody, so the row is `INNER JOIN` and one keypress writes both words. Each also
answers to its words run together, because `innerjoin` is how it gets typed at speed. Keywords
are written in the style's own casing while still filtering on plain text, so casing never
changes what is found.

Nothing but columns is offered after a dot: `u.INNER JOIN` is not a thing.

### Sorting

Match quality first, then group. The groups put what is nearest to hand first — a whole join
predicate, then columns in scope, then what the clause is asking for, then the language, then
the rest of the database. So `Set` in a `SELECT` list offers a `Setting` column above the `SET`
keyword, and after `ON` the predicate outranks the columns it is built from.

After the group comes `Ordinal`, which only columns set. They carry their position in the table,
so the list shows them in **declared order** rather than by name — the order the design has, and
the order `SELECT *` and an INSERT list use. One counter runs across every table in scope, so
each table's columns stay together and in order rather than interleaving with the next table's.
Everything else leaves `Ordinal` at its default and falls through to alphabetical, unchanged.

### Numbering an alias

`AliasFor` appends ` t1`, ` t2` to a table chosen for a `FROM` or a `JOIN`. The numbering walks
up from one and takes the first free name, so a statement holding `t1` and `t3` yields `t2`
rather than `t4`. Both the aliases **and the table names** already in the statement are treated
as taken, because `t1` is a perfectly ordinary table name.

The guards are the substance of it, and each one is a way of writing broken SQL:

| refused where | because |
|---|---|
| an INSERT target, an UPDATE or DELETE target | `INSERT INTO dbo.Orders t1` does not parse. `INTO` sits inside `WantsTables`, so this is checked on the clause itself rather than that flag |
| a name that already has an alias | `dbo.Orders t1 o` — `CanTakeAlias` reads the next significant token, and an ordinary word there is the author's alias. A keyword cannot be one, so `FROM x WHERE` is still fair game |
| a name still being qualified | a dot follows, so the object name is not finished |
| a table valued function's arguments | an open bracket follows, not an alias |
| a procedure or scalar function | not something you select from |

### The list can offer what Tab has to refuse

`JoinCompleter` **declines** when two foreign keys relate the same pair of tables, or when a
table joins to itself: with one keystroke and no way to ask, writing either one would be
guessing. The list is under no such constraint. It shows every candidate — both keys, and both
directions of a self join — because choosing between them is the author's to do, and a list is
the thing that lets them.

The popup never takes focus. The editor keeps it, which is what makes typing-to-narrow work and
keeps the caret blinking where the author left it.

### Filtering

Matching runs against two strings per row: the bare name and the qualified one. That is what
makes a table reachable without knowing its schema — `Tb_Job` finds `TMGR.Tb_JobRequest`, and
choosing it inserts the qualified name.

Four qualities of match, best first:

| rank | match | example against `Tb_JobRequest` |
|---|---|---|
| 0 | the name starts with it | `Tb_Job` |
| 1 | a word inside the name starts with it | `Request`, `Job` |
| 2 | it appears anywhere | `bReq` |
| 3 | the letters appear in order | `jbrq` |

Ties break by group — what is in scope sorts above the rest of the catalogue — then
alphabetically.

## What it completes

| context | keystroke | result |
|---|---|---|
| anywhere in a statement | `Ctrl+K, Ctrl+Space`; `Ctrl+Space` / `Ctrl+J` with the switch on | the list: objects, columns in scope, keywords |
| after `EXEC` or `EXECUTE` | the list | stored procedures first |
| after `ON` in a join | the list | the predicate itself, from the foreign key, above the columns |
| after `FROM` or `JOIN` | the list | the table, its schema, and a numbered alias |
| caret on a `*` in a SELECT list | Tab / `Ctrl+K, Ctrl+X` | the real column list |
| after an unqualified object name | Tab / `Ctrl+K, Ctrl+J` | its schema written in front of it |
| after `JOIN <table> [alias]` with no `ON` | Tab / `Ctrl+K, Ctrl+J` | the `ON` predicate, from the foreign key |
| in an empty `INSERT INTO t (` | Tab / `Ctrl+K, Ctrl+J` | every writable column |
| after `VALUES`, or in its empty brackets | Tab / `Ctrl+K, Ctrl+J` | `@`-parameters matching the column list |
| after `UPDATE t SET` | Tab / `Ctrl+K, Ctrl+J` | `Column = @Column` for every writable column |

"Writable" excludes identity, computed and `rowversion` columns: a value cannot be written to
any of them, so an INSERT or UPDATE list that included them would not run.

## Schemas

A database that keeps nothing in `dbo` is the normal case, not the exception, and none of the
above asks you to write the schema out.

`SchemaIndex.ResolveKey` turns a name as written in a query into the object it means:

| written | resolved |
|---|---|
| `Sec.Sec_Tb_User` | that exact table, or nothing — a wrong schema never falls back |
| `Sec_Tb_User` | `Sec.Sec_Tb_User`, because exactly one schema holds that name |
| `Audit`, held by both `Sec` and `Pms` | nothing: only the author knows which |
| `Shared`, held by `dbo` and `Ops` | `dbo.Shared` — an unqualified name usually means the default schema |

So joins, column lists and assignments all work on an unqualified name outside `dbo`.

`QualifyCompleter` then does the clerical half: Tab on the bare name writes the schema in.
The presses stack, and the **order in `JarvisCompleter` is load bearing** — qualification runs
before the join completer. Writing the join first would produce
`ON Sec_Tb_User.RoleId = r.RoleId` and leave the name unqualified for good, because the second
press would now find a predicate in its way. Qualifying first gives `JOIN Sec.Sec_Tb_User`, and
the next press writes the predicate against the qualified name. Each press does the smaller
thing.

Qualification stops as soon as the name is no longer the last thing on the line — an alias
after it means the author has moved on, and rewriting the name then would be meddling.

The same stacking applies to an INSERT: `INSERT INTO Sec_Tb_User` then Tab gives
`INSERT INTO Sec.Sec_Tb_User`, and Tab again writes its column list.

### A complete word at the caret is not a half typed one

`ListCompleter` turns away a word being typed, because that is when SSMS's own list is open and
the key is not ours. But the word behind the caret after `INSERT INTO dbo.Orders` *is* the table
name — finished, and the very thing being anchored on. Requiring a trailing space before Tab
would be a rule nobody should have to learn, so a partial word that exactly matches the anchor
token is allowed through. Each completion still checks its own anchor, which is what turns away
`INSERT INTO dbo.Ord`.

This resolution lives in `SchemaIndex` in the **engine**, not beside the database reader,
precisely so it can be tested without a server. `SchemaSnapshot` in the VSIX is a thin front
that turns query rows into one.

## The three layers

```
SqlContextAnalyzer     what is the caret looking at?      (Core, no editor dependency)
SchemaIndex            which object does that name mean?  (Core, so the rules are testable)
ISchemaCatalog         what does the database say?        (Vsix, background loaded)
SnippetCommandFilter   who gets this Tab?                 (Vsix, IOleCommandTarget)
```

### 1. Context

`SqlContextAnalyzer` runs the formatter's own lexer and reports the clause, the tables in scope
with their aliases, the qualifier behind the caret, and the partial word being typed. Tables
declared *after* the caret still count, because a `FROM` written later still decides what the
`SELECT` list may refer to.

Each `TableReference` also carries `IsJoined`, `HasOnClause` and its character extent, which is
what lets the join completer find the reference the caret is sitting at the end of.

Text in, context out: no editor types anywhere, which is the only reason any of this can be
tested without SSMS.

### 2. Catalogue

`ISchemaCatalog` adds column detail and foreign keys to the plain names `ISchemaProvider`
already supplied. `StarExpander` keeps the narrower dependency — expanding a star needs names
and nothing else.

`SchemaCache` reads each database once, with two `sys.*` queries, on a background thread, into
an immutable `SchemaSnapshot`. Immutability is the point: the snapshot is built off the UI
thread and read on it, so nothing can change under a reader mid-lookup.

### One snapshot per connection, and no "current"

Snapshots are keyed on **server and database together** — the same database name on two servers
is two different catalogues — and `Prepare` **hands the snapshot back** rather than storing it in
a `Current` field.

That is the whole design, and it was learned the hard way. An earlier version kept a `_current`
snapshot that `Prepare` and every finishing background load assigned to. With query windows open
on several databases at once, whichever one last touched the cache decided what *all* of them
saw: switch to a tab on another database and the suggestions were still the previous one's, and
refreshing only ever fixed the tab you were on.

So `SchemaCache` deliberately does **not** implement `ISchemaCatalog`. It cannot, because the
answer depends on which window is asking. Each caller resolves its own window's connection, gets
that connection's snapshot, and passes *that* to the Core builders. There is no ambient state
left for a second window to disturb.

`Invalidate` removes one connection's entry, so refreshing one database never costs a re-read of
the others. The list header names the database it came from, and the "ready" message names the
server too.

Foreign key rows arrive ordered by constraint then key column ordinal, so appending them pairs
the columns up correctly. That ordering is what makes a two-column key produce two equalities
the right way round.

**Nothing blocks the editor.** A lookup against a database that has not been read yet returns
nothing and starts a load; the feature declines this time and works the next. If the foreign key
query fails, the columns are kept and only join completion goes quiet.

### 3. The Tab gate

`SnippetCommandFilter` sits in front of the editor and does two jobs.

**With the list open**, it routes ↑↓, Page Up/Down, Home/End, Tab, Enter and Escape to the
session. Typing, Backspace and Delete are forwarded to the editor *with their original
arguments* — `pvaIn` carries the typed character, so dropping it would swallow the keystroke —
and the list is re-filtered afterwards. Any other command at all closes the list rather than
leaving it floating over unrelated work.

**With no list open**, it intercepts Tab and nothing else, trying star expansion, snippet
expansion, then the one-key completions. Anything else — and any decline — falls straight
through to `_next.Exec`.

Every feature has its own switch, and each has a keybinding that does the same work without
involving Tab at all, so Tab can be left completely alone.

## Refusing rather than guessing

This is the part that keeps it out of SSMS's way, and the part most of the tests are about.

| situation | why it declines |
|---|---|
| a **half typed word** at the caret | this is exactly when SSMS's list is open |
| a table name in **more than one schema** | `Sec.Audit` or `Pms.Audit`? Only the author knows |
| a name that is **already qualified** | nothing to add, and it says so |
| **no foreign key** between the two tables | there is nothing to transcribe |
| **more than one** foreign key | `BillToCustomerId` or `ShipToCustomerId`? Only the author knows |
| a **self-referencing** key | which alias is the manager and which the employee cannot be read off the names |
| an **unknown table** | including one still being typed |
| a **derived table** | its columns are not in the catalogue |
| a list **already started** | `(OrderDate, ` is the author's, not ours |
| the **join already has an `ON`** | nothing to write |
| **metadata not loaded** | declines now, works once the background read lands |
| inside a **string or comment** | never |

Every refusal returns `false` and leaves the document untouched. `Ctrl+K, Ctrl+J` reports the
reason in the status bar; Tab says nothing, because a message on every Tab press would be noise.

An edit is always an insertion — `Length` is zero on every completion — so nothing that is
already in the document can be lost to one.

## One rough edge, stated plainly

With **Use Jarvis IntelliSense** off, a join completion fires on a fully typed, known table name
even if SSMS's list happens to still be open on that same name. Tab then writes the `ON` rather
than committing a completion that would have inserted the identical text. The outcome is the
same identifier plus a useful predicate, so it is benign — but it is the one place the two can
both have an opinion. Switching Jarvis IntelliSense on removes the question entirely, since
SSMS's list is then not there to have one.

## Not built

- An automatic list that opens as you type. It would race SSMS's own, which is the one thing
  this design will not do; the list is summoned instead.
- `WHERE` predicate suggestions from foreign keys.
- `MERGE` completion.
