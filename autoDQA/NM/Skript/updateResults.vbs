Option Explicit

Dim xlApp, xlBook, xlSheet,xlPath,scriptPath

Dim workBookOpen,i

scriptPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
xlPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(scriptPath)


On Error Resume Next

for i = 0 To 20  'försök 20 gånger
			
		
		'kolla om excel är öppet

		Set xlApp = GetObject(,"Excel.Application")
		'wscript.echo Err

		If Err <> 0 Then
		
			'Excel är inte öppet, så gör det som ska göras
			Set xlApp = CreateObject("Excel.Application")
			Set xlBook = xlApp.Workbooks.Open(xlPath & "\" & WScript.Arguments(0) & ".xlsm")
			xlApp.Application.Run WScript.Arguments(0) & ".xlsm!Modul1.UpdateAllResults", WScript.Arguments(1)
			WScript.Sleep(1000)
			xlBook.Save
			xlBook.Close
			xlApp.Quit
			
			Exit For

		Else
			

			wScript.Sleep(30000)   'vänta 30 sekunder och försök igen

			'kolla om det är "rätt" fil som är öppen
			'For Each wb in xlApp.Workbooks

				'If wb.FullName = xlPath & "\" & WScript.Arguments(0) & ".xlsm Then			

				'Else

				
			'Next

		End If
		
		
		Err.Clear

		Set xlSheet = Nothing
		Set xlBook = Nothing
		Set xlApp = Nothing

	
Next
		

	
