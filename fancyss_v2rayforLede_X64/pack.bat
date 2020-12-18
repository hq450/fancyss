for /d %%X in (*) do "c:\Program Files\7-Zip\7z.exe" a -ttar "%%X.tar" "%%X\"
for %%X in (*.tar) do ("c:\Program Files\7-Zip\7z.exe" a -tgzip "%%X.gz" "%%X" )
for %%X in (*.tar) do (del "%%X")

::.%date:~0,4%%date:~5,2%%date:~8,2%