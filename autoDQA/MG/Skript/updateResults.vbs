Option Explicit

Dim xlApp, xlBook, xlSheet,xlPath,scriptPath

scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
xlPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(scriptPath)

Set xlApp = CreateObject("Excel.Application")

Set xlBook = xlApp.Workbooks.Open(xlPath & "\" & WScript.Arguments(0) & ".xlsm",,,,,,True)

WScript.Sleep(1000)

xlApp.Application.Run WScript.Arguments(0) & ".xlsm!Modul1.UpdateAllResults"

xlBook.Save

xlBook.Close
xlApp.Quit

Set xlSheet = Nothing
Set xlBook = Nothing
Set xlApp = Nothing