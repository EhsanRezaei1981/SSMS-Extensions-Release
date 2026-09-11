![Jarvis — T-SQL toolkit for SQL Server Management Studio](docs/logo/jarvis-wordmark.png)

# Jarvis SSMS Extension

A T-SQL toolkit for **SQL Server Management Studio (SSMS) 21 and 22**, built as a proper VSIX extension
for the Visual Studio shell that SSMS now runs on.

It started as a formatter and is no longer only that. Under one **Jarvis** menu:

| | |
|---|---|
| **Format** | `Ctrl+K, Ctrl+D` lays the script out to your house style, and every format is checked token by token before it is applied |
| **IntelliSense** | a completion list that knows your schema — tables, columns, procedures, functions, join predicates read off the foreign keys, and aliases numbered for you |
| **Snippets** | a shortcut and Tab, from a file that is yours to edit |
| **Query history** | every query you run, searchable by text, server and date |
| **Export** | the results grid to a real `.xlsx` or to pipe delimited CSV, split into files you can actually open |
| **Map** | geometry and geography columns drawn on a real map, a layer per column, with address search |
| **F12** | the definition of the procedure under the caret, open and ready to change |

Built and verified against **SSMS 22.6.0** (shell 18.x, .NET Framework 4.7.2, x64).

## Download and install

**Latest release: 2026.911.1.1**

### ⬇ [Download Jarvis for SSMS](https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/releases/latest/download/Jarvis.SSMSExtension-latest.vsix)

**Close SSMS, double click the file, start SSMS.** The **Jarvis** menu is on the menu bar. That
is the whole install — SSMS's own installer does it, and there is nothing to extract.

That link always gives you the newest release, so it is safe to bookmark or pass on. This one is
2026.911.1.1 — [or pick a specific version](https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/releases/download/v2026.911.1.1/Jarvis.SSMSExtension-2026.911.1.1.vsix).

SSMS has to be closed: a running instance holds the extension registry open and the install
fails with nothing installed.

### If you would rather use a script

Every release also carries a
[zip of the extension and the install scripts](https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/releases/download/v2026.911.1.1/Jarvis.SSMSExtension-2026.911.1.1.zip).
Extract it, close SSMS, and run `.\install.ps1` from the extracted folder.

It does more than double clicking does: it checks SSMS is closed and says which process is
holding it, removes an older copy first, and verifies the package actually registered rather than
assuming it did. `.\install.ps1 -DryRun` shows the resolved paths and changes nothing.

Worth having when an install has already gone wrong, or for putting Jarvis on several machines
without clicking through anything.

### Updating

Download the new `.vsix` and double click it, or run `.\install.ps1` from the new zip. There
is no need to uninstall first, and SSMS must be closed either way.

Jarvis also checks for updates itself and tells you when there is a newer version — nothing is
downloaded or installed without you saying so.

### If something looks wrong

```powershell
.\doctor.ps1        # what is installed, where, and whether it registered
.\uninstall.ps1     # remove it; -Force skips the prompt
```

Every version, with its notes and its own `SHA256SUMS`, is on the
[Releases page](https://github.com/EhsanRezaei1981/SSMS-Extensions-Release/releases). What changed in each is in [CHANGELOG.md](CHANGELOG.md).

> The **Source code (zip)** and **Source code (tar.gz)** on each release are added by GitHub
> automatically for the tag. They are a snapshot of this repository — the scripts and docs — not
> the extension. The files listed above are the ones to download.



---

## What you get

Everything lives under a **Jarvis** menu on the main menu bar:

```
Jarvis
├── SQL Formatter ▸
│     ├── Format Document           Ctrl+K, Ctrl+D   (Ctrl+K, Ctrl+Y also works)
│     ├── Format Selection          Ctrl+K, Ctrl+F
│     ├── Copy as Formatted         Ctrl+K, Ctrl+G
│     ├── Format All Open Documents Ctrl+K, Ctrl+A
│     └── Format on Save             off by default
├── Active Style ▸
│     ├── Jarvis Standard
│     ├── Jarvis Gold
│     ├── Jarvis Compact
│     ├── Jarvis River
│     ├── Jarvis Light
│     └── Jarvis Custom...
├── IntelliSense ▸
│     ├── Expand * to Columns        Ctrl+K, Ctrl+X
│     ├── Complete Join or List      Ctrl+K, Ctrl+J
│     ├── Show Completion List       Ctrl+K, Ctrl+Space
│     ├── Use Jarvis IntelliSense     on/off — turns SSMS IntelliSense off
│     ├── Go To Definition           F12
│     └── Refresh Metadata          Ctrl+K, Ctrl+R
├── History ▸
│     ├── Query History...          Ctrl+K, Ctrl+Q
│     └── Clear Query History...
├── Results ▸
│     ├── Export Results to Excel...            Ctrl+K, Ctrl+E
│     ├── Export Results to CSV (pipe delimited)...  Ctrl+K, Ctrl+V
│     └── Show on Map...            Ctrl+K, Ctrl+M
├── Snippets ▸
│     ├── Expand on Tab             on/off
│     ├── Edit Snippets...          Ctrl+K, Ctrl+T
│     ├── Reload Snippets
│     └── List Snippets             Ctrl+K, Ctrl+L
├── Updates ▸
│     ├── Check for Updates...
│     └── Check Automatically        on by default
├── Options...                      Ctrl+K, Ctrl+O
├── Licence...
├── About Jarvis...
└── Uninstall Jarvis...
```

The same commands are on the **editor right click menu** under a Jarvis sub menu, and on a
dockable **Jarvis** toolbar. Settings are in **Tools ▸ Options ▸ Jarvis**.

Every shortcut is a **Ctrl+K** chord, because that is where the first ones went and a second
prefix is one more thing to remember. The letters miss the standard editor chords rather than
being perfectly mnemonic — `Ctrl+K, Ctrl+C` is comment selection, `Ctrl+K, Ctrl+U` uncomment,
and `Ctrl+K` with **K**, **N**, **P**, **W** or **H** belongs to bookmarks and the task list.
Taking one of those would break a key you use all day to gain one you use occasionally.

**They are assigned rather than only declared.** A key in a `.vsct` is a *default*, and the shell
applies defaults while it builds its keyboard map — so on a machine that has already run SSMS,
shortcuts added by a newer version are ignored in silence: the command sits in **Tools ▸ Options ▸
Environment ▸ Keyboard** with nothing beside it. Jarvis assigns them itself on the first start of
each version, and writes what it set to the output pane. **A command that already has a shortcut
is left alone**, so one you chose yourself is never overwritten, and one you deliberately removed
stays removed.

Five things have **no** shortcut on purpose: the six style profiles and the four toggles, which
you set once rather than invoke; About, Licence and Check for Updates, which nobody reaches for
in a hurry; and **Clear Query History** and **Uninstall Jarvis**, because a keystroke should not
be able to throw away your history or remove the extension. All of them are in the menu.

## Snippets

Type a shortcut and press **Tab**:

| you type | you get |
|---|---|
| `ssf` ⇥ | `SELECT *` / `FROM ` with the caret after FROM |
| `sfw` ⇥ | a SELECT with a FROM and a WHERE |
| `ij` ⇥ | `INNER JOIN` with an indented `ON` under it |
| `cte` ⇥ | a common table expression, ready to fill in |
| `tc` ⇥ | TRY/CATCH wrapped around a transaction, with the rollback and THROW written for you |
| `sp` ⇥ | a CREATE PROCEDURE with a dated, attributed header |

**22** ship by default. When the word in front of the caret is not a shortcut, Tab does exactly
what it always did, so indenting and IntelliSense are unaffected.

**Jarvis ▸ Snippets ▸ List Snippets** (`Ctrl+K, Ctrl+T` edits the file, `Ctrl+K, Ctrl+L` lists
it) writes every shortcut with its description to the **Jarvis output pane**, along with the file
they came from and how many there are — the answer to "what can I type?" without opening the
file. It brings the Output window forward, which it did not always do: it selected the Jarvis
pane inside a window that was closed, so the command appeared to do nothing.

### They are yours to change

**Jarvis ▸ Snippets ▸ Edit Snippets...** opens the file. Save it and the very next Tab uses the
new version; no restart, no reload step.

It lives in `%APPDATA%\Jarvis\snippets.txt` unless you say otherwise in
**Tools ▸ Options ▸ Jarvis ▸ General ▸ Snippet file**, which has a **...** button to pick one — point it at a shared folder so a team
works from one set, or at a repository so they are under source control. A missing folder is
created and a new file is started with the built-in snippets; a path that cannot be written to
falls back to the default **and says so** — in the Jarvis output pane and in the About box, naming
the path it could not use. One setting, one file, and the file it is really reading is under
**Jarvis ▸ About ▸ Files**.

```
[hdr] Comment header block
-- =============================================
-- Author:  $user$
-- Created: $date$
-- Purpose: $end$
-- =============================================
```

A line starting with `[` begins a snippet; everything under it is the body. Redefining a
shortcut that already exists replaces it, so overriding a default is one paste.

Tokens are resolved **at the moment you press Tab**, not when the snippet was written:

| token | becomes |
|---|---|
| `$end$` | where the caret ends up |
| `$date$` `$time$` `$datetime$` `$year$` | now |
| `$user$` `$machine$` | the Windows account, this machine |
| `$guid$` | a fresh uppercase GUID, different every expansion |
| `$$` | a literal dollar sign, for `$action` and the like |

Multi-line snippets are re-indented to match the line you expand them on, and the whole
expansion is a single undo step. `#temp` tables and `--` comments in a body are safe: `#` only
means "comment" above the first snippet.

## IntelliSense

### Turning it on

**Jarvis ▸ IntelliSense ▸ Use Jarvis IntelliSense.** One switch, and it works both ways:

| switch | Jarvis | SSMS |
|---|---|---|
| **on** | suggests as you type | its IntelliSense is switched **off** |
| **off** | list only on `Ctrl+K, Ctrl+Space` | its IntelliSense is switched back **on** |

Only ever one list on screen, and you choose whose. Jarvis does it two ways at once: it writes
SSMS's own IntelliSense setting, which is what makes the choice stick for windows opened later,
**and** drives the **Query ▸ IntelliSense Enabled** command, which takes effect in the window
you are in right now.

The status bar says which of the two worked, and the write is read back before it counts as
success. If it cannot reach either, it says so and opens the options dialog for you — the switch
is **Tools ▸ Options ▸ Text Editor ▸ Transact-SQL ▸ IntelliSense ▸ Enable IntelliSense**.

**The setting is read when a query window is created**, so unchecking it does nothing for a
window that is already open — reopen the tab, or restart SSMS.

Belt and braces: whenever the Jarvis list opens, and on every keystroke while it is open, it
**dismisses any other completion list** through the editor's own brokers. So even if something
else puts a list on screen, only one of them stays.

Two courtesies worth knowing: if you already had SSMS IntelliSense off yourself, switching Jarvis
off again **leaves it off** — Jarvis only restores what Jarvis turned off. And uninstalling or
disabling the extension hands it back automatically.

It is **on from a fresh install**, so Jarvis works the way it is meant to without a setup step.
That does switch SSMS's own IntelliSense off — only one list should ever appear — and the two
courtesies above are why that is safe to undo: turn Jarvis IntelliSense off and SSMS's comes
back exactly as you had it.

### The star tells you it can expand

Put the caret after a `*` and Jarvis says so, with the number of columns it would write:

```
 SELECT * │ Tab to expand 14 columns
 FROM TMgr.Tb_JobRequest
```

Everything T-SQL allows between `SELECT` and the list is understood, so `SELECT TOP 100 *`,
`SELECT DISTINCT *`, `SELECT TOP (@n) PERCENT *` and `SELECT TOP 10 WITH TIES *` all expand — as
does a qualified `o.*` after any of them. A number is only taken as part of `TOP`, so
`SELECT 100 * 2` stays the multiplication it is.

The note appears **only where it is true**. It asks the expander whether this particular star
would expand, rather than guessing from the character, so it never appears on a multiplication,
on a star outside a `SELECT` list, or on a table Jarvis has not read — and never promises
something Tab will not do. It goes as soon as the caret moves, takes no focus and swallows no
keys: Tab expands exactly as it always did.

Turn it off under **Tools ▸ Options ▸ Jarvis ▸ IntelliSense ▸ Show the Tab hint beside a ***.
It also stays away when **Expand \* to columns on Tab** is off, rather than advertising a Tab
that would only indent.

### What you picked last comes up first

The list remembers what you choose from it and floats those to the top next time, because
writing SQL against a database you know means reaching for the same handful of tables over and
over.

It promotes **within a group, never across one**. The groups already mean something — a column
of a table in the current `FROM` sits above a table from elsewhere — and a recently used table
jumping over the columns you are in the middle of listing would be worse than no ordering at
all. Everything not recently picked stays exactly where the filter put it.

The last 30 picks are kept, for the session. Entries from another database are harmless: the
ordering only rearranges rows the list already produced, so a name that is not there cannot
surface.

### Hover to see what something is

Rest the mouse on a name and Jarvis shows what it holds, in a grid you can select from:

```
 SELECT * FROM TMgr.Tb_JobRequest
        ┌──────────────────────────────────────────────────────────────┐
        │ TMgr.Tb_JobRequest  —  table                                 │
        │ 14 columns  -  select rows, then Ctrl+C                      │
        ├───┬───────────────┬───────────────┬──────────┬───────────────┤
        │ # │ Column        │ Type          │ Null     │ Notes         │
        ├───┼───────────────┼───────────────┼──────────┼───────────────┤
        │ 1 │ JobRequestId  │ int           │ not null │ identity      │
        │ 2 │ StreetId      │ int           │ not null │               │
        │ 3 │ Description   │ nvarchar(200) │ null     │               │
        │ 4 │ Created       │ datetime      │ not null │ default       │
        ├───┴───────────────┴───────────────┴──────────┴───────────────┤
        │ [ Copy names ] [ Copy rows ]                                 │
        └──────────────────────────────────────────────────────────────┘
```

A **table or view** shows its columns with their types, what may be null, and what is an
identity, computed or defaulted — the things that decide how an `INSERT` has to be written. A
**procedure or function** shows its parameters instead, with a **Direction** column marking
`OUTPUT`, and optional ones noted.

**It is a panel, not a tooltip.** It stays open when you move onto it, so you can select rows —
click, Ctrl+click, Shift+click — and take them with **Ctrl+C**. **Copy names** gives a comma
separated column list to paste into a `SELECT`; **Copy rows** gives the whole grid tab separated,
so it lands in a spreadsheet as columns. With nothing selected, both copy everything. Escape
closes it, as does clicking elsewhere or typing.

It reads the catalogue Jarvis already holds, so it never asks the server and never delays
anything: hovering a name in a database that has not been read yet simply shows nothing rather
than starting a query.

Turn it off under **Tools ▸ Options ▸ Jarvis ▸ IntelliSense ▸ Describe a name when I hover on it**.

### The list

With it on, the list appears **as you type** — on the second letter of a word, straight after a
dot, and on the space after a word that introduces something: `ON`, `FROM`, `JOIN`, `INTO`,
`SET`, `VALUES`, `WHERE`, `AND`, `EXEC`, a comma, an opening bracket. So typing
`... t2 ON ` shows the join predicate without your having to ask for it.

A space anywhere else is left alone — after a table name comes an alias, after `=` comes a
value, and there is nothing useful to offer in either. It offers keywords, tables, columns and functions together:

```
 SELECT * FROM Sec.Sec_Tb_User u inn
                                 ┌──────────────────────────────┐
                                 │ INNER JOIN           keyword │
                                 │ LEFT OUTER JOIN      keyword │
                                 │ RIGHT OUTER JOIN     keyword │
                                 └──────────────────────────────┘
```

Type `inn` and `INNER JOIN` is the first row — the **whole construct**, not a bare `INNER`, so
one keypress writes both words. `GROUP BY`, `IS NOT NULL`, `CROSS APPLY`, `BEGIN TRY`,
`ROW_NUMBER () OVER` and the rest work the same way, and each answers to its words run together
(`innerjoin`, `groupby`). Keywords come out in your style's casing.

`Ctrl+K, Ctrl+Space` opens it by hand at any time. With the switch on, **`Ctrl+Space` and
`Ctrl+J` open it too** — SSMS's own list is off, so those keys would otherwise do nothing; with
the switch off they stay SSMS's, untouched.

### After ON, the whole predicate

```
 FROM Sec.Sec_Tb_Role r JOIN Sec.Sec_Tb_User u ON 
                                                  ┌────────────────────────────────────────────┐
                                                  │ u.RoleId = r.RoleId        FK_User_Role    │
                                                  │ u.UserName                 NVARCHAR(100)   │
                                                  │ r.RoleName                 NVARCHAR(100)   │
                                                  └────────────────────────────────────────────┘
```

The predicate is written out whole, read off the foreign key, and it leads the list — after `ON`
that is the answer, not an ingredient of one. Composite keys come as one row with the `AND`
already in place. The columns follow underneath for when you want to write your own.

This is where the list beats the Tab completion. `Ctrl+K, Ctrl+J` has to **refuse** when two
foreign keys relate the same pair of tables, or when a table joins to itself, because choosing
for you would be guessing. The list simply offers every candidate and lets you pick:

```
 o.CustomerId = c.CustomerId        FK_Orders_Customers
 o.ShipToCustomerId = c.CustomerId  FK_Orders_ShipTo
```

A self join offers both directions — `m.ManagerId = e.EmployeeId` and `m.EmployeeId = e.ManagerId`.

### Aliases, numbered for you

Choosing a table for a `FROM` or a `JOIN` writes an alias after it, carrying on from whatever
the statement already uses:

```sql
SELECT * FROM TMgr.Tb_JobRequest t1
INNER JOIN TMgr.Tb_JobRequestFile t2 ON t2.JobRequestId = t1.JobRequestId
```

It counts past gaps rather than reusing a number, so `t1` and `t3` taken gives you `t2`. An
alias you chose yourself is never trodden on, and a table genuinely **named** `t1` takes its
name out of the running — reusing it would compile into something nobody meant.

And it stays out of the places an alias does not belong:

- an **INSERT target** and an **UPDATE** or **DELETE** target, where one does not parse
- a name that **already has an alias** after it, so you never get `dbo.Orders t1 o`
- a name **still being qualified**, where a dot comes next
- a **procedure or scalar function**, which is not something you select from

Turn it off, or change the letter, under **Tools ▸ Options ▸ Jarvis ▸
IntelliSense**.

### Everything in the database, not just tables

Tables, views, **stored procedures**, scalar and table valued functions are all read and all
offered, each labelled with what it is:

```
 EXEC Pms_Sp
 ┌────────────────────────────────────────────────┐
 │ Pms.Pms_Sp_Patron_Create      Pms  procedure   │
 │ Sec.Sec_Sp_User_Create        Sec  procedure   │
 └────────────────────────────────────────────────┘
```

What leads the list depends on where you are. After `EXEC` the procedures come first, because
nothing else can be executed. After `FROM` the tables, views and table valued functions come
first, because a procedure cannot be selected from. Everything else still follows underneath
rather than being hidden.

Sorting puts what is nearest to hand first: the columns of the query you are writing, then what
the clause is asking for, then the language, then the rest of the database. So `Set` in a
`SELECT` list offers your `Setting` column above the `SET` keyword.

**Columns come out in the order the table declares them**, not alphabetically — the same order
you see in the design, in `SELECT *`, and in an INSERT list, so checking one against another is
straightforward. With several tables in scope each keeps its own order and they do not
interleave. Everything else stays alphabetical.

Nothing but columns is offered after a dot — `u.INNER JOIN` is not a thing.

```
 Columns of TMGR.Tb_JobRequest  (4)
 ┌────────────────────────────────────────────┐
 │ JobRequestId                 INT identity  │
 │ RequestedOn            DATETIME2(3) not null│
 │ RequestedBy                  INT           │
 │ Status                NVARCHAR(30)         │
 └────────────────────────────────────────────┘
  Tab or Enter to insert   Esc to close
```

- **↑ ↓** move, **Page Up/Down** jump, **Home/End** go to the ends
- **Tab** or **Enter** inserts the selected row
- **Esc** closes it
- **keep typing** to narrow the list; **Backspace** widens it again

With **Use Jarvis IntelliSense** off it is never automatic: it appears only when you ask, so it
cannot race SSMS's own list. `Ctrl+Space`, which is SSMS's, is left alone either way.

**You never need to know the schema.** The list filters on the *bare* name and inserts the
*qualified* one: type `Tb_Job` and `TMGR.Tb_JobRequest` is what comes up, and choosing it writes
`TMGR.Tb_JobRequest`. Matching is forgiving — a prefix (`Tb_Job`), a word inside the name
(`Request`), or just the letters in order (`jbrq`) all find it.

### Choosing a procedure writes the call

The catalogue knows a routine's parameters, their order and their types, which is exactly the
part that is tedious to type and easy to get wrong from memory. So choosing one writes the call,
not just the name:

```sql
EXEC TMgr.usp_UpdateJobRequest
    @JobRequestId = ,  -- int
    @Status       = ,  -- varchar(20)
    @ChangedBy    = ;  -- nvarchar(100), optional
```

Named arguments rather than positional, so the call survives somebody adding a parameter in the
middle of the procedure later, and reads as documentation in the meantime. The `=` line up, the
type of each is shown beside it, and optional parameters say so.

**OUTPUT parameters bring their whole round trip**, because a call that omits the keyword fails
silently and one that names an undeclared variable does not run at all:

```sql
DECLARE @IOJsonParams nvarchar(max);
EXEC TMgr._Sp_Action_Create
    @IOJsonParams = @IOJsonParams OUTPUT;  -- nvarchar(max), output
SELECT @IOJsonParams AS IOJsonParams;
```

The declarations go above and the SELECT below — but only when the line holds nothing but the
`EXEC`. A procedure named inside a larger expression gets the parameter list alone, since
rewriting from the start of that line would not be safe.

A function gets its brackets and arguments on one line instead: `dbo.fnCalc(@a, @b)`.

Nothing is written in any doubtful case — an object the catalogue does not know, or one that
takes no parameters at all. An empty parameter list and "no idea" are deliberately different
answers: the first is safe to write a call for, the second is not.

### F12 goes to the definition

Put the caret on a procedure, function, view or trigger and press **F12**. Jarvis reads the
source with `OBJECT_DEFINITION` and opens it in a new query window on your connection, ready to
change. It is a script rather than a live object, so nothing is altered until you execute it.

The name is read as written: bracketed names with spaces, three part `Db.Schema.Object` names,
and the caret at either end of the word all work.

SSMS binds nothing to F12 in a query window, so Jarvis registers the key itself rather than
borrowing a command that is never dispatched. It is also on **Jarvis ▸ IntelliSense ▸ Go To
Definition**.

It **declines rather than guessing**, and says why on the status bar: nothing under the caret, no
such object in this database, or a definition that cannot be read because it is encrypted or your
login lacks permission.

### The one-key completions

These write a single right answer straight in, with no list, because there is nothing to choose
between — *pure transcription from the catalogue*:

| you type | press | you get |
|---|---|---|
| `SELECT * FROM dbo.Orders o` (caret on the `*`) | ⇥ | the real column list |
| `FROM Sec_Tb_User` | ⇥ | `FROM Sec.Sec_Tb_User` — the schema written in for you |
| `FROM dbo.Orders o INNER JOIN dbo.Customers c` | ⇥ | `ON c.CustomerId = o.CustomerId`, read out of the foreign key |
| `INSERT INTO dbo.Orders` — no trailing space needed | ⇥ | ` (OrderDate, CustomerId, Total)`, every column a value can be written to |
| `INSERT INTO dbo.Orders (` | ⇥ | the same names, inside brackets you already opened |
| `INSERT INTO dbo.Orders (CustomerId, Total) VALUES ` | ⇥ | `(@CustomerId, @Total)`, matched to the column list |
| `UPDATE dbo.Orders SET ` | ⇥ | `OrderDate = @OrderDate, CustomerId = @CustomerId, ...` |

Identity, computed and `rowversion` columns are left out of the INSERT and UPDATE lists, because
a value cannot be written to them.

### Schemas

Nothing here needs you to write the schema. `FROM Sec_Tb_User` is resolved to `Sec.Sec_Tb_User`
for every completion, as long as exactly one schema holds a table of that name — so joins,
column lists and assignments all work on an unqualified name outside `dbo`.

Tab on that bare name writes the schema in as well, and the presses stack: the first gives you
`JOIN Sec.Sec_Tb_User`, the second the `ON` predicate. When two schemas hold the same table
name, nothing is written and `Ctrl+K, Ctrl+J` says which schemas they were.

### It refuses rather than guesses

Every one of these declines instantly unless the catalogue settles the question outright, and a
decline hands the keystroke straight back:

- **a half typed word is never touched** — which is the whole conflict story, since that is
  exactly when SSMS's list is open
- a table name held by **more than one schema** is left for you, and the schemas are named
- a join with **no foreign key** between the tables, or **more than one**, is left for you
- a **self-referencing** key is left for you: which end is which cannot be read off the names
- an **unknown table**, a **derived table**, a list you have **already started** — all declined
- **metadata still loading** declines this time and works the next; nothing ever blocks the editor

`Ctrl+K, Ctrl+J` runs the one-key completions without involving Tab at all, and *says* why when
it declines. `Ctrl+K, Ctrl+X` does the same for `*`, and `Ctrl+K, Ctrl+Space` opens the list.
Each feature has its own switch under **Tools ▸ Options ▸ Jarvis ▸ IntelliSense**,
so Tab can be left completely alone.

### Where the metadata comes from

The connection behind the query window that has focus, found through SSMS's own object model —
and, where the script says otherwise, the database it says.

**A `USE` in the script wins.** SSMS reports the database a window was *connected* to and nothing
more: its connection info has no current-database member at all, only what the connect dialog
filled in. So the last `USE` before the caret decides, and it survives `GO` — a batch separator
ends a batch, not the connection. A `USE` in a comment, a string, a query hint or a column named
`use` is not a switch.

Which connection the loaded catalogue belongs to is under **Jarvis ▸ About ▸ Right now**, named
rather than counted, for exactly the moment the list looks wrong for the tab you are in.

Objects, columns, foreign keys and routine parameters are read once per database with four
`sys.*` queries, kept as an immutable snapshot, and loaded on a background thread. Tables, views,
stored procedures and functions all come across — procedures are read separately from columns,
because they have none and would otherwise never appear.

Losing either of the last two queries costs only what it feeds: no foreign keys means no join
predicates, no parameters means no call templates. Neither costs the columns.

**One cache entry per server *and* database.** Windows open on different databases each get
their own, so switching tabs switches catalogue with them — and a background load finishing for
one database never changes what another window sees. The list header names the database it is
drawing from, so with several tabs open you can see at a glance which one you are getting.

**Jarvis ▸ IntelliSense ▸ Refresh Metadata** (Ctrl+K, Ctrl+R) re-reads just the database of the window you
are in, when you have just changed a table. The others stay cached.

## Query history

Every query you execute is recorded: **when**, **which server**, **which database**, and the
**query itself**. **Jarvis ▸ History ▸ Query History...** opens a dockable window to search it.

```
Search  [ update patron        ]   Server [ SQL01 ▾ ]
From    [ 2026-09-01 ]  To [ 2026-09-02 ]   [Today] [Clear filters]

When                 Server   Database   Query
2026-09-02 08:53:10  SQL01    Pms        UPDATE Pms.Pms_Tb_Patron SET IsActive = 0 WHERE ...
2026-09-01 16:20:44  SQL02    TMgr       SELECT * FROM TMgr.Tb_JobRequest t1 INNER JOIN ...
```

**Search** looks in the query text, the server and the database at once, so typing a server name
finds that server's queries without saying which field you meant. Several words all have to
match, in any order: `update patron` finds an UPDATE against `Pms_Tb_Patron` either way round.

**Server** narrows to one server. **From** and **To** narrow to a date range — both ends
included, so picking today for both finds today's queries. The filters combine.

Select a row to see the whole query underneath. **Open in editor** puts it in a new query window
against your current connection; **Copy** puts it on the clipboard. Double-click or Enter opens.

What gets recorded is what SSMS runs: the **selection** when you have one, the whole window
otherwise.

### Where it lives, and turning it off

`%APPDATA%\Jarvis\query-history.log` by default — one line per query, plain text, so you can
read it with anything. Change where it lives in **Tools ▸ Options ▸ Jarvis ▸
General ▸ History file**, which has a **...** button to pick one: a synced folder to carry it between machines, or a drive you would
rather query text lived on. A folder that does not exist is created, and a path that cannot be
written to falls back to the default rather than silently dropping every query. It holds **5000 queries** by default and drops the oldest past that, so it cannot grow
without bound.

It records query text. If that is not appropriate for what you work on, turn it off in
**Tools ▸ Options ▸ Jarvis ▸ General ▸ Record every query I run**. Passwords are
never recorded — for a SQL login the history keeps the user name only.

**Jarvis ▸ History ▸ Clear Query History...** deletes the lot, after asking.

## Exporting results

Right click anywhere on the **results grid** after running a query:

```
Jarvis: Export to Excel (.xlsx)
Jarvis: Export to CSV (pipe delimited)
```

Both are also on **Jarvis ▸ Results**. Both write the **column names as the first row**.

### Every result set, not just the one you clicked

A batch that returns several result sets exports **all** of them, in the order SSMS shows them —
it used to export whichever grid was focused and leave the rest behind without saying so.

| | |
|---|---|
| **Excel** | one workbook, **one worksheet per result set** — `Result 1`, `Result 2`, … |
| **CSV** | **one file per result set** — `report-1.csv`, `report-2.csv`, … |

The formats differ because the formats differ: a workbook holds sheets, so three result sets
belong in three sheets of one file; a CSV file holds exactly one table, so three result sets can
only be three files.

Two details worth knowing. Excel's ceiling of 1,048,575 data rows still applies, so a set past it
continues on `Result 2 (2)` and so on. And a **size** limit is not applied to a multi-sheet
workbook — splitting it by bytes would scatter the sheets across files, which is the arrangement
one workbook exists to replace; with a single result set the size splitting works exactly as it
always did. CSV honours the limit either way, so a large set 2 becomes `report-2.csv`,
`report-2 (2).csv` and so on.

A set that cannot be read is skipped rather than failing the export — three good result sets
should not be lost to a fourth that turned out to be something else — and the count of what was
written is reported when it finishes.

**Excel** produces a real `.xlsx` — an OOXML workbook, not a CSV wearing the wrong extension, so
Excel opens it without complaining that the format does not match. The header row is bold and
frozen, so scrolling a long result set keeps the names in view. Values that are genuinely
numbers are written as numbers, so the sheet can sum and sort them.

Anything that only *looks* like a number stays text. `007` stays `007`, and so does a phone
number with a leading zero: turning it into `7` would lose something you cannot get back.

**CSV** is pipe delimited — `|` rather than `,`, because a comma turns up inside SQL data far
more often than a pipe does. A field carrying a pipe, a quote or a line break is quoted, and
quotes inside it doubled, so a value can never split one field into two or one row into two. The
file is UTF-8 with a byte order mark, without which Excel opens it in the system codepage and
mangles every accented character.

Both dialogs suggest a name from the query window, stamped with the time, so two exports never
quietly overwrite each other.

> The right click items are appended to the grid's menu. SSMS builds that menu itself, and where
> it does not use the WinForms menu the items appear on a Jarvis menu of their own instead. The
> **Jarvis ▸ Results** entries work either way.

### Millions of rows: splitting the export

Every export asks how to split it **first**, because the answer depends on the result set — a
hundred thousand rows of three integers and a hundred thousand rows carrying an XML column are
nothing alike, and you only know which you have once the query has run.

```
2,483,921 rows, 7 columns — about 1.4 GB in total.

  ( ) One file, whatever the size
  (o) Split every  [ 500,000 ]  rows
  ( ) No file larger than  [ 30 ]  MB

  About 28 files, each around 51.2 MB.
```

It tells you the size before you choose, and what your choice will produce before it produces
it — finding out you have made three hundred files afterwards is no use. The dialog opens on
whatever you picked last time.

**By rows** is exact. **By size** is a ceiling, not a target: each file is filled as close to the
limit as it will go, and each one is measured after it is written — anything over the limit is
written again smaller. So the limit holds.

Sizes are measured **exactly** for CSV — every row is measured by writing it through the same
code that writes the file, into a counter that keeps the byte count instead of the bytes. So the
byte order mark, the header repeated on each file and every accented character are counted as
they will actually be stored, not estimated.

**Every file carries the header row**, so each one stands on its own. Files are numbered with as
many digits as the count needs — `-01`..`-10`, `-001`..`-100` — so they sort in order. A split
workbook names its sheets `Results (1)`, `Results (2)`. An export that fits in one file keeps
exactly the name you chose, with nothing appended.

Two things are not preferences:

- A **row is never split across files.** A single row larger than the maximum gets a file of its
  own and overshoots it, because cutting the row would corrupt the data.
- A **worksheet is capped at Excel's own limit** of 1,048,575 data rows however you set the
  split, because a workbook past that is not one Excel will open.

For `.xlsx` the size cannot be known before the file is written — it is a compressed zip — so
Jarvis measures each workbook it writes and sizes the next one from what that came to. The first
file of an export may miss; from the second on it is using this result set''s own compression
ratio. CSV needs none of this: it is exact from the first file.

A long export runs on a background thread with a progress window and a **Cancel** button, so the
shell stays usable and an export started by mistake can be stopped. Reading the rows out of the
grid has to happen on the UI thread — the grid will only answer its owner — but the message
queue is pumped as it goes, so the window stays live throughout.

## Geometry on a map

**Jarvis ▸ Results ▸ Show on Map...**, or **Ctrl+K, Ctrl+M**, draws the spatial columns of the
results grid on a real map — points, lines and polygons, and the multi and collection forms of
each. It reads the grid you are already looking at, so nothing is queried twice, and a selection
maps just that selection.

The shortcut works with the focus in the results grid as well as in the editor, which is where
you will usually be when you want it.

```
┌─ Layers ─────────────┬──────────────────────────────┐
│ 🔍 Search an address │                              │
│                      │      ●───────●               │
│ Map  [ TomTom    ▾ ] │      │       │    pan, zoom  │
│ [ Zoom to fit ]      │      ●───────●    click a    │
│                      │                  shape for   │
│ ▣ ■ route            │        ●         its row     │
│   1 204 shapes       │                              │
│   ☐ Swap lat/long    │                              │
│                      │                              │
│ ▣ ■ boundary         │                              │
│   38 shapes, SRID 4326                              │
└──────────────────────┴──────────────────────────────┘
```

**A dataset is a result set, not a column.** A query selecting a shape, its centroid and its two
end points is *one* dataset of however many rows, with a tick per geometry column deciding which
of them is drawn:

```
┌─ Layers ────────────────────────┐
│ Results                         │
│ 2 records  ·  SRID 4326         │
│ Geometry columns                │
│   ☑ ■ SegGeom      (2)          │
│   ☐ ■ SegCentroid  (2)          │
│   ☐ ■ SegStart     (2)          │
│   ☐ ■ SegEnd       (2)          │
│   ☐ ■ SegGeomStr   (2)          │
│ ☐ Swap lat/long                 │
│ Label  [ RoadName          ▾ ]  │
│ ▸ Records (2)                   │
└─────────────────────────────────┘
```

**Only the first column is drawn to begin with.** Four geometries per row piled on top of one
another is unreadable, so the rest are yours to switch on. Ticking several shows several.

Clicking a shape shows the rest of its row. **Zoom to fit** frames what is currently visible.

**The panel folds away, and resizes.** Drag the thin strip beside it to make it wider or
narrower; click the chevron next to that to slide it out of the way and back. Two strips rather
than one, so an unsteady click never turns into a resize. A width you drag to is remembered, so
hiding and showing brings the panel back the size you left it. It is animated rather than snapping:
the map grows into the space the panel leaves, and a map that changes size instantly gives no
hint of where the panel went or that it can be brought back. The handle stays put either way,
which is why it sits outside the panel rather than in it.

**The window always opens**, even with no results, no spatial column, or nothing drawable in
one. It says in its own pane what is missing and what to do about it, rather than refusing with
a message box — and the map and the address search are worth having on their own.

**Pick what each shape is labelled with.** Each dataset has a **Label** dropdown listing its
columns — choose `NAME` and every suburb is captioned with its name, the way SSMS's
own Spatial results tab does it. It is per layer because two layers rarely share a column worth
showing: a boundary layer has a suburb name, a route layer a job number. The columns offered are
the ones already sent with the geometry, so choosing one asks the server nothing and redraws
instantly. Labels start off.

**Each record has its own tick too.** Open **Records** under a dataset and every row is listed
with its number, its colour and **the value of whichever column you chose as the label** — so
the list reads the same as the captions on the map, and changing the label column relabels both.
Switch any one off without disturbing the rest, or use **All on** / **All off** for the lot. A record is a row, so
switching it off removes it from every geometry column at once. What you switch off stays off
through a **Swap lat/long** or a change of map provider, rather than quietly coming back.

The list is built when you first open it, so a layer of a thousand shapes costs nothing until
you want to pick through it, and it lists the first 500 — past that the ticks stop being
something anybody scrolls through. Records beyond the limit stay on the map; they simply have no
tick of their own, and the pane says so.

**Every record is drawn in its own colour**, so shapes that touch or overlap stay apart. The
colour comes from the row number rather than a list, stepping the hue far enough each time that
neighbouring rows never look alike, and each layer starts from a different point so two layers
still read as two layers.

**All the result sets are drawn, not just the one in focus.** A batch that returns several sets
stacks a grid for each, and every one of them is read; layers are then labelled
`Result 2 · VectorData` so two sets with a column of the same name stay apart.

### Points made from two number columns

A great deal of spatial data never becomes a geometry column — it sits as two numbers per point:

```
START_X_LEFT   START_Y_LEFT   START_X_RIGHT   START_Y_RIGHT   CENTER_X   CENTER_Y
27.98364100   -26.05278440    27.98364100     -26.05278440    27.98454   -26.05301
```

Jarvis finds those pairs and offers each as a point layer alongside the real geometry columns —
`START_LEFT`, `START_RIGHT` and `CENTER` from the row above — switched on with a tick like any
other.

Pairing is **by name, one token apart**: `START_X_LEFT` goes with `START_Y_LEFT` and never with
`START_Y_RIGHT`, which is the mistake a looser rule makes. `X`/`Y`, `LON`/`LAT`, `LNG`/`LAT` and
`LONGITUDE`/`LATITUDE` are all understood, as prefix or suffix, with underscores or in camel
case — `CenterX` reads the same as `CENTER_X`. Each column belongs to one pair only.

**The values have to agree.** Both columns must parse as numbers within coordinate range before
anything is drawn, so a `MIN_X`/`MIN_Y` pair holding prices matches by name and is then thrown
out rather than plotted in the Atlantic. A row where either is blank simply has no point.

### Binary or text, either will do

A spatial column is recognised two ways, so it does not matter how the shapes reach the grid:

| what the grid shows | example |
|---|---|
| the binary SSMS normally displays | `0xE6100000010C151DC9E53F343AC0...` |
| the shape written out as text | `LINESTRING (27.983641 -26.0527844, 27.9836853 -26.0528202, ...)` |

So `SELECT Route FROM ...` and `SELECT Route.STAsText() FROM ...` both map, as does a `varchar`
column somebody keeps shapes in, and PostGIS's `SRID=4326;POINT (...)` form. Text needs no
decoding and no spatial assembly, so it works even where the binary route cannot.

A column is only taken as spatial if its values actually parse — the bare word `POINT` in a text
column is a word, not a shape, and is left alone.

### Which map

Eight to choose from, switchable on the window itself:

| provider | key | notes |
|---|---|---|
| **TomTom** | yes | the default |
| **TomTom satellite** | same key | imagery on the default provider's key, so satellite costs no extra setting up |
| **Google Maps** | yes | drawn through its own API — its terms do not allow its tiles in another library |
| **OpenStreetMap** | **none** | always available, and what is offered when a key is missing |
| **Azure Maps** | yes | road map, with its own address search |
| **Azure Maps satellite** | same key | imagery, which is usually what spatial data wants behind it |
| **MapTiler** | yes | clean street styling, with its own address search |
| **Stadia Maps** | yes | pale Alidade styling, good under coloured shapes |

Keys go in **Tools ▸ Options ▸ Jarvis ▸ Map**, one per provider — Azure's two entries share the
one Azure key.

**With no key at all, the map draws OpenStreetMap.** It needs none, so a fresh install shows your
geometry immediately without anybody visiting a developer portal first. The provider list moves
to OpenStreetMap along with the map, so the box never names something other than what is on
screen, and the status line says which key is missing every time it draws — not once at startup,
because whoever opens the map an hour later has forgotten. Your chosen provider is left set in
the options, so entering its key later is all it takes.

Each keyed provider does its own address search and reverse geocoding, so the key you enter
covers the map *and* the searching. Attribution is rendered on the map for every one, as their
terms require.

**Switching view without leaving the map.** The layers button at the **top right** of the map
lists every background this machine can actually draw — road and satellite together — so going
from streets to imagery is one click on the map rather than a trip through the provider list.
Google is switched with its own **Map / Satellite** buttons, since Google is drawn by its own API
rather than as tiles.

A provider with no key is **left out of that list** rather than offered and then failing: a view
that turns the map grey when picked is worse than one that was never there. The button itself is
not shown when only one background is available — a switcher with nothing to switch to is
furniture. So entering a second key is what makes the switcher appear.

### The address under a shape

Click a shape and its popup has an **Address here** button. It looks up the address at the exact
point you clicked — not the middle of the shape, which for a long road is nowhere near where you
were looking — and writes it beside the button.

It is asked for rather than fetched automatically. A click is not a request to call somebody
else's geocoder, and a popup that queried the internet every time it opened would be both a
nuisance and, on a paid key, a bill. One point at a time, never in a loop over a result set.

Whichever provider is drawing the map does the lookup, so the key already entered is the only
one needed: TomTom and Google use their own reverse geocoders, and OpenStreetMap uses Nominatim
— which permits a reverse lookup, unlike the autocomplete it asks callers not to do.

### Right click the map

Right click anywhere on the map for a menu of that point:

```
Copy latitude (y), longitude (x)
Copy longitude (x), latitude (y)
────────────────────────────────
Address here
Centre the map here
────────────────────────────────
Remove the point                 ← only when there is one
```

**Points accumulate.** Ask for as many addresses as you like — each keeps its own marker and its
own popup, so two places can be compared side by side. **Remove this point** takes the one
nearest where you right clicked, so clicking a pin removes *that* pin rather than the newest, and
**Remove all points** appears once there is more than one. Neither row is shown when there is
nothing to remove.

**Moving the map is animated** — a search result, a coordinate, a country or **Zoom to fit** all
fly rather than cut, so you can see which way the map went. How far the wheel zooms is yours to
set under **Tools ▸ Options ▸ Jarvis ▸ Map ▸ Mouse wheel zoom**: Stepped moves whole levels and
keeps tiles at their own scale, Smooth moves in quarters, Balanced is halfway.

Both orders are offered because both are wanted: latitude first to paste into a map site,
longitude first to paste into a `geometry::Point`. **The x and y are named alongside** wherever a
latitude and longitude are shown — the two namings are the commonest way to get a coordinate the
wrong way round.

**Address here** marks the point and writes the address into its popup, so the answer sits beside
the place it describes rather than only on the status line.

The menu is a list in one place, so adding to it later is a label and what it does — no new
plumbing.

### Your own x and y

**Go to x and y** takes a pair of numbers, **either way round**:

| you type | with **South Africa** chosen | with **(anywhere)** |
|---|---|---|
| `151.2093 -33.8688` | long 151.2093, lat −33.8688 — 151 cannot be a latitude | the same |
| `-33.8688 151.2093` | the same point, order irrelevant | the same |
| `27.9767704 -26.0558576` | long 27.98, lat −26.06 | long 27.98, lat −26.06 |
| `-26.0558576 27.9767704` | **the same point** — the country settles it | long −26.06, lat 27.98, as entered |

**The chosen country settles what the numbers cannot.** Both of `-26.0558576` and `27.9767704`
are legal latitudes, so no rule about ranges can separate them — but one ordering is in South
Africa and the other is two thousand miles out in the Atlantic, and if South Africa is the
country being searched then only one of them was meant. Jarvis takes whichever lands nearer the
country and says it worked it out.

With **(anywhere)** selected there is nothing to reason from, so the pair is taken exactly as
entered — the first number as x — which is the order the map providers themselves read, and the
status line says so.

It marks the point, **and looks the address up underneath** — somebody typing a coordinate out of
a query usually wants to know where it actually is. The status line names the x and the y beside
the latitude and longitude, so a point that landed oddly can be read rather than guessed at.

A number past 90 can only be a longitude, so most real coordinates sort themselves out whichever
order they were typed in; the country settles the rest. Comma, space, tab or semicolon all
separate the pair, and the numbers are read invariantly so a machine set to a comma decimal
separator reads them the same.

### Address search

**Country** above the search confines it to one country, starting at the one this machine is set
to — because somebody searching "Main Road" almost certainly means the country they are in, and
searching the planet buries it among thousands. Pick **(anywhere)** to search the world instead.
Changing the country re-runs whatever is already typed.

Type an address and matches appear as you go, from three letters. Pick one and the map goes there
and marks it; Escape clears it. The provider drawing the map does the searching, so the key
already entered for the map is the only one needed. On OpenStreetMap the typing goes to Photon,
which is the same OpenStreetMap data from a service built for typing into — Nominatim, which
Enter uses, does not permit autocomplete.

### Which way round your coordinates are

SQL Server stores `geometry` and `geography` the opposite way round, and nothing in the results
grid says which a column is. The same bytes read one way give `POINT (28.05 -26.20)` and the
other `POINT (-26.20 28.05)` — one is Johannesburg, the other is the Indian Ocean, and both are
perfectly valid, so no amount of checking the value can separate them.

Jarvis reads the values exactly as stored and works the order out from them: a coordinate past 90
can only be a longitude, so those settle themselves. Where the numbers cannot settle it —
Johannesburg at 28° east is inside latitude range either way — **Tools ▸ Options ▸ Jarvis ▸ Map ▸
Coordinates are longitude first** decides, and each layer's **Swap lat/long** tick shows what was
assumed and corrects it in one click.

Curved geometry — `CIRCULARSTRING`, `COMPOUNDCURVE`, `CURVEPOLYGON` — is counted and reported as
skipped, never approximated: there is no GeoJSON for a curve, and drawing a guess would put
something on the map the database did not say. An SRID that is not latitude and longitude is
flagged on its layer rather than drawn somewhere wrong.

The map opens in its own window with its own message loop, so Delete, Home, End and the arrow
keys work in the search box — on SSMS's thread the shell claims those keys as editor commands
before a text box can see them — and SSMS stays usable while it is open.

## Updates

Jarvis checks the public release page each time SSMS starts and tells you when there is a newer
version, showing what changed. **Nothing is downloaded or installed without you choosing it**:
the notice offers Download, Release page, Skip this version and Remind me later, and closing it
means later.

**Jarvis ▸ Updates ▸ Check for Updates...** does the same on demand and, unlike the automatic
check, also says when you are already up to date. **Check Automatically** turns the startup check
off, as does **Tools ▸ Options ▸ Jarvis ▸ Updates**; the tick box on the notice is the same
setting, so it can be switched off from the thing interrupting you.

The check is anonymous, sends nothing about you or your servers, runs off the UI thread so it can
never delay SSMS starting, and is silent when there is no news — no network, a refusing proxy or
a rate limit all pass without a word. Installing an update needs SSMS closed, because
VSIXInstaller will not run while it is open, and the notice says so rather than starting
something that fails afterwards.

## The part that matters: it cannot break your script

Formatting only ever moves whitespace. To prove it, the formatted text is lexed again and
compared with the original **token by token**. If a single token was added, dropped or altered,
the format is thrown away and your document is left exactly as it was, with an explanation in the
output window.

That check is what makes *Format on Save* safe to turn on. It is on by default and you can switch
it off in the options if you ever need to.

On top of that:

- String literals, `[bracketed]` and `"quoted"` identifiers are copied through byte for byte.
- Comments are preserved, including nested `/* ... /* ... */ ... */` blocks.
- An unterminated literal, a stray parenthesis or a half typed statement will not throw; the
  formatter lays out what it understands and copies the rest through.
- Formatting is **idempotent** — running it twice gives the same result as running it once.

## Installing

Close SSMS, then:

```powershell
.\install.ps1        # installs into SSMS 21/22
```

Check what it will do first with `.\install.ps1 -DryRun`, which prints the resolved paths
and changes nothing.

### More than one SSMS installed

SSMS versions install side by side, and putting the extension into the wrong one looks exactly
like putting it into none of them. When several are found you are asked which to use:

```
More than one SQL Server Management Studio is installed.
Which one should this extension be installed on?

  [1] SSMS 22.6.0
      C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE
  [2] SSMS 21.4.0
      C:\Program Files\Microsoft SQL Server Management Studio 21\Release\Common7\IDE
  [A] all of them
```

Answer in advance with `-Version` (a major version such as `22`, or any prefix of the full
version), or take every one of them with `-All`:

```powershell
.\install.ps1 -Version 22
.\install.ps1 -All
```

`install.ps1`, `uninstall.ps1`, `update.ps1`, `doctor.ps1` and `check-registration.ps1` all
resolve the target the same way and all accept `-Version` and `-All`, so a diagnosis always
reports on the installation the install actually wrote to. `update.ps1` asks once and passes
the answer to the steps it runs. If SSMS lives somewhere unusual, point `SSMS_IDE_PATH` at its
`Common7\IDE` folder.

`install.ps1` hands the package to the `VSIXInstaller.exe` that ships inside SSMS. If that
refuses the SKU, it falls back to unpacking the extension straight into

```
%LOCALAPPDATA%\Microsoft\SSMS\<version>_<id>\Extensions\Jarvis.SSMSExtension\
```

which is where SSMS looks for per user extensions. You can force that route with
`.\install.ps1 -Method Copy`.

To remove it from inside SSMS, **Jarvis ▸ Uninstall Jarvis...** hands the extension to the
shell's own extension manager and it goes on the next restart — the same route as Extensions,
Manage Extensions, Uninstall.

Or with SSMS closed:

```powershell
.\uninstall.ps1            # asks first; -Force skips the prompt
.\uninstall.ps1 -DryRun    # list what would be removed, change nothing
```

Neither route touches your snippet file or your query history. They live in `%APPDATA%\Jarvis\`,
outside the extension folder, so reinstalling finds them where they were. Delete them yourself
if you want them gone.

## Style profiles

Pick one from **Jarvis ▸ Active Style**. **Jarvis Gold is the default** — it is the style this
formatter was built to produce. Anything you have already chosen is left alone; the default only
applies where nothing has been picked.

| Profile | What it looks like |
|---|---|
| **Jarvis Gold** *(default)* | Aligned: one space after the clause keyword, lists under their first item, trailing commas, DECLARE and SET aligning their `=`, `ON` on its own line. Written up in [docs/jarvis-gold-style.md](docs/jarvis-gold-style.md) |
| **Jarvis Standard** | 4 space indents, upper cased keywords, trailing commas, wrap at column 120 |
| **Jarvis Compact** | 2 space indents, wrap at 160, joins and predicates kept together |
| **Jarvis River** | Every column on its own line with the comma in front |
| **Jarvis Light** | Normalise whitespace and casing, change as few line breaks as possible |
| **Jarvis Custom** | Everything on the Style options page is yours to set |

### Before

```sql
select o.orderid,o.orderdate, c.companyname as Customer, sum(od.quantity*od.unitprice) as Total
from dbo.orders o inner join dbo.customers c on c.customerid=o.customerid
where o.orderdate>='2024-01-01' and o.status in (1,2,3) group by o.orderid,o.orderdate,c.companyname
```

### After

```sql
SELECT o.orderid, o.orderdate, c.companyname AS Customer, SUM(od.quantity * od.unitprice) AS Total
FROM dbo.orders o
INNER JOIN dbo.customers c
    ON c.customerid = o.customerid
WHERE o.orderdate >= '2024-01-01' AND o.status IN (1, 2, 3)
GROUP BY o.orderid, o.orderdate, c.companyname
```

Every statement is given the semicolon it is missing, whichever style is picked. Never after
BEGIN, AS, THEN, ELSE, a label, a comma or an operator, and never twice. It is the only setting
that writes something you did not type, so the safety check is relaxed to allow exactly that and
nothing else — a format that changed anything but whitespace and terminators is still refused.
Turn it off under **Tools ▸ Options ▸ Jarvis ▸ General ▸ Terminate statements with ;**.

Line breaking is driven by whether things **fit**. A short list stays on one line; the same list
past the right margin explodes one item per line. Set `List breaking` to `OnePerLine` if you would
rather it always exploded.

## Telling the formatter to leave something alone

Fence it off:

```sql
-- jarvis-format: off
SELECT     this   ,   stays
       EXACTLY  as-is
-- jarvis-format: on
```

Everything between the two markers is copied through character for character.

## A style file for the whole team

Drop a `.jarvis-sqlformat` file next to your scripts, or anywhere above them in the folder tree,
and it overrides the personal settings for scripts underneath it. Commit it and everybody formats
the same way.

```ini
# .jarvis-sqlformat
IndentSize = 4
MaxLineLength = 120
KeywordCase = Upper
IdentifierCase = Preserve
CommaStyle = Trailing
ListStyle = Auto
NewLineBeforeOn = true
AlignAssignments = true
```

Write your current settings out with `jsqlfmt --write-config .jarvis-sqlformat`.

## The same formatter on the command line

`jsqlfmt` is the identical engine, for pre commit hooks and build servers.

```bash
jsqlfmt db/**/*.sql              # format in place
jsqlfmt --check -r db            # exit 1 if anything is unformatted (a CI gate)
jsqlfmt --diff schema.sql        # show what would change
cat query.sql | jsqlfmt -        # stdin to stdout
jsqlfmt --style Compact -r db    # use a named profile
```

Exit codes: `0` success, `1` changes pending under `--check`, `2` bad usage, `3` a file could not
be formatted safely.

## Licence

Free to use, for anything, including at work. Install it on as many machines as you like and
pass it to whoever you like, provided the copy is complete, unmodified and keeps its notice.

Not free to sell: it may not be sold, charged for, or included in anything sold or offered as a
paid product or service, and it may not be passed off as somebody else's work. All other rights
are reserved.

It comes with no warranty of any kind. The full terms are in [LICENSE.txt](LICENSE.txt).
## Known limits

- Casing is decided from word lists plus context, not from a full parse. Words that are far more
  often column names than keywords — `RowCount`, `Level`, `Source`, `Target`, `Rows` — keep the
  casing you typed. `OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY` is still cased correctly, because
  those positions are recognised specifically.
- Missing statement terminators are handled heuristically. T-SQL without semicolons is ambiguous
  in places, and a misread costs a line break, never a token.
- Column aliases are not vertically aligned. Assignments in `SET` and `DECLARE` runs are.
- Exporting reads the results grid, so it exports what the grid holds. A query still running, or
  one sent to text or to file rather than to grid, has nothing to read.
- The query history records what was sent to the server, not what came back. It does not store
  results, row counts or how long a query took. Only queries run after Jarvis loads are recorded:
  SSMS keeps no history of its own for Jarvis to read.
- F12 and the procedure call templates read the catalogue, so they work on what Jarvis has read.
  A procedure created since the last read is found after **Ctrl+K, Ctrl+R**.
- A snippet file left in the old `%APPDATA%\Jarvis SQL Formatter` folder is moved to
  `%APPDATA%\Jarvis` the first time Jarvis looks for it. The original is copied rather than
  moved, then deleted, so a file that cannot be deleted still leaves the snippets readable.
