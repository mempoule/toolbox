Sub Formatting_invoices()
'
' Formatting_invoices Macro
'

'
' CSV Splitting
    Columns("A:A").Select
    Selection.TextToColumns Destination:=Range("A1"), DataType:=xlDelimited, _
        TextQualifier:=xlDoubleQuote, ConsecutiveDelimiter:=False, Tab:=False, _
        Semicolon:=False, Comma:=True, Space:=False, Other:=False, FieldInfo _
        :=Array(Array(1, 1), Array(2, 1), Array(3, 1), Array(4, 1), Array(5, 1), Array(6, 1), _
        Array(7, 1), Array(8, 1), Array(9, 1), Array(10, 1), Array(11, 1), Array(12, 1), Array(13, 1 _
        ), Array(14, 1)), TrailingMinusNumbers:=True

' Autoformat all cells
    Cells.Select
    Cells.EntireColumn.AutoFit

' Header Formating
    Rows("1:1").Select
    With Selection.Interior
        .Pattern = xlSolid
        .PatternColorIndex = xlAutomatic
        .ThemeColor = xlThemeColorAccent1
        .TintAndShade = 0.399975585192419
        .PatternTintAndShade = 0
    End With
    Selection.Font.Size = 12
    Selection.Font.Bold = True
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With

' Filter columns
    Columns("A:N").Select
    Selection.AutoFilter
    ActiveSheet.Range("$A$1:$N$159").AutoFilter Field:=1, Criteria1:="<>"

' Number replace . to ,
    If ActiveSheet.Name = "invoices" Then
        Range("G:G,E:E,H:H").Select
    Else
        Range("D:D").Select
    End If
    Selection.Replace What:=".", Replacement:=",", LookAt:=xlPart, _
        SearchOrder:=xlByRows, MatchCase:=False, SearchFormat:=False, _
        ReplaceFormat:=False, FormulaVersion:=xlReplaceFormula2

' Column width tweak
    If ActiveSheet.Name = "invoices" Then
        Columns("A:A").ColumnWidth = 11.71
        Columns("A:A").ColumnWidth = 12.57
        Columns("B:B").ColumnWidth = 11.71
        Columns("C:C").ColumnWidth = 7
        Columns("D:D").ColumnWidth = 15.86
        Columns("E:E").ColumnWidth = 8.71
        Columns("F:F").ColumnWidth = 9
        Columns("G:G").ColumnWidth = 12
        Columns("H:H").ColumnWidth = 16.57
        Columns("G:G").ColumnWidth = 14.14
        Columns("G:G").ColumnWidth = 18
        Columns("H:H").ColumnWidth = 20.86
        Columns("F:F").ColumnWidth = 12
        Columns("E:E").ColumnWidth = 11.29
        Columns("E:E").ColumnWidth = 12.86
        Columns("D:D").ColumnWidth = 17.86
        Columns("D:D").ColumnWidth = 21.43
        Columns("C:C").ColumnWidth = 10.86
        Columns("B:B").ColumnWidth = 15.57
        Columns("B:B").ColumnWidth = 16.29
        Columns("H:H").ColumnWidth = 19
        Columns("J:J").ColumnWidth = 58.14
    Else
        Columns("A:A").ColumnWidth = 17.14
        Columns("B:B").ColumnWidth = 13
        Columns("C:C").ColumnWidth = 14.43
        Columns("E:E").ColumnWidth = 21
        Columns("F:F").ColumnWidth = 70
        Columns("G:G").ColumnWidth = 12
        Columns("H:H").ColumnWidth = 16.57
        Columns("G:G").ColumnWidth = 14.14
        Columns("G:G").ColumnWidth = 70
    End If

' Text Wrapping
    If ActiveSheet.Name = "invoices" Then
        Range("G:G").Select
    Else
        Range("F:F").Select
    End If
    With Selection
        .VerticalAlignment = xlBottom
        .WrapText = True
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With


' Remove pseudo bullshit error coming from numerical imported as text
    Dim Rng_e As Range
    Dim Rng_g As Range
    Dim Rng_h As Range
    Dim LR As Long 'LR = Last Row for Understanding

    LR = Cells(Rows.Count, 1).End(xlUp).Row

    If ActiveSheet.Name = "invoices" Then

        Set Rng_e = Cells(2, 5).Resize(LR)
        Set Rng_g = Cells(2, 7).Resize(LR)
        Set Rng_h = Cells(2, 8).Resize(LR)

        For Each c In Rng_e.Cells
            c.Select
            c.Value = ActiveCell * 1
        Next

        For Each c In Rng_g.Cells
            c.Select
            c.Value = ActiveCell * 1
        Next

        For Each c In Rng_h.Cells
            c.Select
            c.Value = ActiveCell * 1
        Next
    Else
        Set Rng_d = Cells(2, 4).Resize(LR)
        For Each c In Rng_d.Cells
            c.Select
            c.Value = ActiveCell * 1
        Next
    End If

' align first cols
    If ActiveSheet.Name = "invoices" Then
        Columns("A:I").Select
    Else
        Columns("A:E").Select
    End If
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlCenter
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
End Sub

