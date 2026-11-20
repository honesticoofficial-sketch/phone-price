Get-ChildItem "C:\Users\User01\AppData\Local\Programs\Python\", "C:\Program Files\Python*", "C:\Python*" -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue | Select-Object FullName
Get-Command node -ErrorAction SilentlyContinue | Select-Object Name, Source
