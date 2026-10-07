@echo off
echo Starting the container and dropping you into a shell...
echo Once inside, try running: conda run -n minerl xvfb-run python run.py --env_kind minecraft
echo.

docker run -it --rm ^
    -v "%cd%":/workspace ^
    curiosity-minerl bash
