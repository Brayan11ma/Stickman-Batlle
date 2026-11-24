@echo off
cd /d "%~dp0"
python -m pip install -r requirements.txt
echo.
set HOST=
set /p HOST=IP o direccion del servidor (Enter = la ultima usada): 
if "%HOST%"=="" (
  python client\client.py
) else (
  python client\client.py %HOST%
)
pause
