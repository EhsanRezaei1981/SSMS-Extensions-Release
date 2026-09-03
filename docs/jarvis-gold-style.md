# Jarvis Gold — the aligned style

A **column aligned** style: clause keywords take a single space, and everything after them lines
up under the first item rather than at a fixed indent.

> **Changed.** Gold began as the river style taken from `Pms.Pms_Sp_Patron_Create` — clause
> keywords padded to a common width, leading commas. It was redefined to the shape below.
> `Jarvis River` still has leading commas if you want them back.

## 1. Clause keywords take one space; the body lines up under the first item

```sql
SELECT @a = SD.StateDivisionId,
       @b = SD.StateDivisionHierarchy
FROM Pub.Pub_Tb_StateDivision SD
WHERE SD.StateDivisionIsBase = 1;
```

No padding after the keyword. The list anchors on wherever its first item landed, so a second
line sits directly under the first.

## 2. Trailing commas

```sql
SELECT alpha,
       bravo,
       charlie
FROM dbo.t;
```

## 3. DECLARE and SET both align their name, type and value columns

```sql
DECLARE @ErrorCode       INT           = 0,
        @ErrorMessage    NVARCHAR(MAX),
        @ErrorKey        VARCHAR(250),
        @IsTranBegunHere BIT           = 0;
```

```sql
UPDATE t1
SET t1.NAME_ALT       = t2.NAME_ALT,
    t1.CouldBeForeign = t2.CouldBeForeign,
    t1.GeoSuburb      = t2.GeoSuburb
```

A declaration with no value ends at its type: the padding that would line the `=` up is
suppressed when only a comma follows it, so no line reads `VARCHAR(250)     ,`.

## 4. A join predicate goes on its own line; AND and OR stay with it

```sql
FROM dbo.TableSuburbs t1
INNER JOIN DGS_SouthAfrica_Stage.dbo.TableSuburbs t2
    ON t2.NAME = t1.NAME AND t2.city = t1.CITY AND t2.PROVINCE = t1.PROVINCE
WHERE t1.CITY_OFFICIAL IS NULL OR t1.CITY_OFFICIAL = '';
```

The join sits at the statement's own indent rather than under the FROM item. `AND` and `OR` do
not take a line each — a predicate reads as one thought.

## 5. Every statement is terminated

A statement with no `;` gets one. Never after `BEGIN`, `AS`, `THEN`, `ELSE`, a label, a comma or
an operator, and never twice. This is the only setting that writes a token the author did not,
so the safety check is relaxed to allow exactly that and nothing else.

## 6. Control-flow conditions are padded inside their parentheses

```sql
IF ( @InnerCall = 0 )
IF ( @PatronType IS NULL )
IF ( EXISTS (   SELECT 1
                FROM Pms.Pms_Tb_Patron PTP
                WHERE PTP.PatronCode = @PatronCode ))
```

`TOP ( 1 )` follows the same rule.

When the condition is *nothing but* a nested bracket — `EXISTS ( ... )`, `NOT EXISTS ( ... )` —
the outer bracket has no work of its own, so it stays on the `IF` line and lets the sub-query
do the breaking. The closing brackets then cuddle: `@PatronCode ))`, never `@PatronCode ) )`.

A condition that does have work of its own keeps the exploded shape, because there the outer
bracket really is holding two things apart:

```sql
IF (
    EXISTS (   SELECT 1
               FROM dbo.T ) AND @x = 1
)
```

## 7. A broken CASE lines up against the column CASE sits in

```sql
    PasswordToOpen = CASE WHEN @RemovePassword = 1
                              THEN NULL
                          ELSE IIF(@PasswordToOpen IS NULL, PasswordToOpen, @PasswordToOpen)
                     END
```

The first WHEN rides on the CASE line; THEN steps in one indent under it; later WHENs and the
ELSE return to the first WHEN column; END returns to the CASE column. A CASE that fits on one
line is still left there.

## 8. An INSERT column list breaks one name per line, inside its bracket

```sql
INSERT INTO TMgr.Tb_JobRequestFile ( JobRequestId,
                                     JobTypeFileTypeId,
                                     Filename,
                                     FileSize,
                                     UserId_UploadedBy )
```

The bracket is padded inside, so the names start two columns past it and every comma lands
squarely under the `(` itself. A list that fits on one line is still left there.

Two things share the shape `identifier (` — a column list and a function call — and they are
laid out differently on purpose. A call is never broken however long it runs (rule 4), because
exploding one reads worse than the long line; a column list always breaks once it is too long,
because reading it is how you check it against the `VALUES` underneath.

## 9. Sub-queries align after their opening parenthesis

`(` then three spaces, and the inner statement is column aligned from there:

```sql
SET @VTResult = (   SELECT TOP 1 VTLocationTypeResult
                    FROM @TblPhones AS TFT
                    WHERE LocationTypeId IS NOT NULL AND dbJarvisFunctions.Pub.Pub_Fn_OutputJsonIsSuccessful (TFT.VTLocationTypeResult) = 0 );
```

The closing parenthesis stays on the last line.


## 10. A procedure signature indents its parameters; an EXECUTE runs long

```sql
ALTER PROCEDURE [Pms].[Pms_Sp_Patron_Create]
    @IOJsonParams NVARCHAR(MAX) OUTPUT
AS
BEGIN
```

```sql
EXECUTE @IOJsonParamsTemp = Pub.Pub_Fn_Check @RequestInfo = @RequestInfoJson, @GlobalTableCode = 'PmsPatron', @DataJson = @DataJson, @GTCD = @GTCD;
```

## 11. Blocks

`BEGIN` / `END` on their own lines, four space body indent, `END;` terminated. A single
statement body of an `IF` is indented without `BEGIN`:

```sql
IF ( @Parent IS NULL )
    SET @Parent = @StateDivisionHierarchy;
```

## Open points

These are assumptions; say the word and any of them can change.

| point | assumption |
|---|---|
| `IIF(...)` appears without a space in the sample, unlike other functions | treated as an inconsistency; **all** functions get the space |
| Keyword casing | upper, as in the sample |
| Identifier casing | preserved exactly as typed |
| Comments | left exactly where the author put them, including the Persian ones |
| Line width | no hard wrap observed; long lines are left long rather than broken |
