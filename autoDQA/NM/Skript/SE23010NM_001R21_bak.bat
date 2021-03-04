echo %1
rem timeout 20 /nobreak
start /wait C:\imageJ\imageJ.exe -macro G:\MF\Diagnostik\autoDQA\NM\imageJ\NM_DQA.ijm G:\MF\Diagnostik\autoDQA\NM\SE23010NM_001R21_head1.dcm,2,2
timeout 60 /nobreak
G:\MF\Diagnostik\autoDQA\NM\skript\updateResults.vbs Millenium_VG