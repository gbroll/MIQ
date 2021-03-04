Dim objShell
Set objShell = Wscript.CreateObject("WScript.Shell")

objShell.Run "G:\MF\Diagnostik\autoDQA\MG\skript\updateResults.vbs MG002R18" 

' Using Set is mandatory
Set objShell = Nothing

