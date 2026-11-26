@echo off
nasm src/mario.asm -f bin -o MARIO.COM
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)
echo Build successful: MARIO.COM created.
