echo %1
timeout 6 /nobreak
C:\imageJ\ij.jar -port0 -batch G:\MF\Diagnostik\autoDQA\MG\imageJ\mammoDQA.ijm G:\MF\Diagnostik\autoDQA\MG\MG002R18.dcm
timeout 6 /nobreak
G:\MF\Diagnostik\autoDQA\MG\skript\updateResults.vbs MG002R18