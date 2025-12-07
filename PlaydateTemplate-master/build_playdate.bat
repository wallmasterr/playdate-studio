@echo off
REM Playdate C Project Build Script for Windows
REM Based on official Playdate SDK documentation: https://sdk.play.date/2.0.3/Inside%20Playdate%20with%20C.html

setlocal enabledelayedexpansion

REM Get the current directory
cd /d "%~dp0"
set "PROJECT_DIR=%CD%"

echo ========================================
echo Playdate C Project Build Script
echo ========================================
echo(

REM Check if CMake is installed
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake is not installed or not in PATH
    echo Please install CMake from https://cmake.org/download/
    pause
    exit /b 1
)

echo Checking CMake version...
cmake --version
echo(

REM Check for Playdate SDK
set "SDK_FOUND=0"
set "SDK_PATH="

REM Check if playdate directory exists in current project
if exist "playdate\C_API" (
    set "SDK_FOUND=1"
    set "SDK_PATH=!PROJECT_DIR!\playdate"
    echo Found Playdate SDK in project directory: !SDK_PATH!
    echo.
)

REM Check PLAYDATE_SDK_PATH environment variable
if "!SDK_FOUND!"=="0" (
    if defined PLAYDATE_SDK_PATH (
        if exist "!PLAYDATE_SDK_PATH!\C_API" (
            set "SDK_FOUND=1"
            set "SDK_PATH=!PLAYDATE_SDK_PATH!"
            echo Found Playdate SDK via PLAYDATE_SDK_PATH: !SDK_PATH!
            echo;
        )
    )
)

REM If still not found, ask user
if "!SDK_FOUND!"=="0" (
    echo ========================================
    echo Playdate SDK not found!
    echo ========================================
    echo.
    echo The Playdate SDK is required to build this project.
    echo.
    echo According to the official documentation:
    echo See: https://sdk.play.date/2.0.3/Inside Playdate with C.html
    echo(
    echo You need to either:
    echo   1. Set the PLAYDATE_SDK_PATH environment variable
    echo   2. Place the SDK in a 'playdate' folder in this directory
    echo   3. Enter the SDK path below
    echo.
    echo Your SDK should be at: C:\Users\PC\Documents\PlaydateSDK
    echo.
    set "SDK_PATH="
    set /p SDK_PATH="Enter Playdate SDK path (or press Enter to skip): "
    
    if not defined SDK_PATH (
        echo.
        echo ERROR: No path provided.
        echo.
        echo Please set PLAYDATE_SDK_PATH environment variable or run this script again.
        echo.
        echo To set the environment variable permanently:
        echo   1. Open System Properties ^> Environment Variables
        echo   2. Add new variable: PLAYDATE_SDK_PATH
        echo   3. Set value to: C:\Users\PC\Documents\PlaydateSDK
        echo.
        pause
        exit /b 1
    )
    
    REM Remove quotes if present
    set "SDK_PATH=!SDK_PATH:"=!"
    
    REM Check if path exists and has C_API
    if not exist "!SDK_PATH!" (
        echo.
        echo ERROR: The specified path does not exist: !SDK_PATH!
        pause
        exit /b 1
    )
    
    if not exist "!SDK_PATH!\C_API" (
        echo.
        echo ERROR: The specified path does not contain a C_API folder.
        echo Path checked: !SDK_PATH!\C_API
        echo Please verify the path is correct.
        pause
        exit /b 1
    )
    
    set "SDK_FOUND=1"
    echo.
    echo Found Playdate SDK at: !SDK_PATH!
    echo.
)

REM Set environment variable for this session
if "!SDK_FOUND!"=="1" (
    set "PLAYDATE_SDK_PATH=!SDK_PATH!"
    echo Using Playdate SDK from: !SDK_PATH!
    echo(
    
    REM Create symlink in project directory if SDK is not already there
    if not exist "playdate" (
        if not "!SDK_PATH!"=="!PROJECT_DIR!\playdate" (
            echo Creating symlink to Playdate SDK in project directory...
            mklink /J "playdate" "!SDK_PATH!" >nul 2>&1
            if !ERRORLEVEL! NEQ 0 (
                echo Note: Could not create symlink (may need admin rights)
                echo Using SDK path via PLAYDATE_SDK_PATH environment variable.
            ) else (
                echo Symlink created successfully.
            )
            echo(
        )
    )
)

REM Create build directory
if not exist "build" (
    echo Creating build directory...
    mkdir build
)

echo ========================================
echo Building Playdate Project
echo ========================================
echo(

REM Configure with CMake
echo Step 1: Configuring CMake...

REM Set PLAYDATE_SDK_PATH for CMake
set "PLAYDATE_SDK_PATH=!SDK_PATH!"

REM Try different CMake generators (use -B to specify build directory, -S for source)
set "BUILD_DIR=!PROJECT_DIR!\build"
set "SOURCE_DIR=!PROJECT_DIR!"
cmake -B "!BUILD_DIR!" -S "!SOURCE_DIR!" -G "MinGW Makefiles" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: MinGW Makefiles generator failed, trying Visual Studio...
    cmake -B "!BUILD_DIR!" -S "!SOURCE_DIR!" -G "Visual Studio 17 2022" -A x64 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo WARNING: Visual Studio generator failed, trying NMake...
        cmake -B "!BUILD_DIR!" -S "!SOURCE_DIR!" -G "NMake Makefiles" 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo.
            echo ERROR: CMake configuration failed
            echo.
            echo Please ensure you have one of the following installed:
            echo   - MinGW (for MinGW Makefiles)
            echo   - Visual Studio (for Visual Studio generators)
            echo   - Visual Studio Build Tools (for NMake Makefiles)
            echo.
            echo According to the documentation, you can also manually run:
            echo   cmake .. -G "YourGenerator"
            echo.
            pause
            exit /b 1
        )
    )
)

echo(
echo Step 2: Building project...
cmake --build "!BUILD_DIR!" --config Release 2>&1
set "BUILD_EXIT_CODE=!ERRORLEVEL!"

echo(
echo ========================================
if "!BUILD_EXIT_CODE!"=="0" (
    echo Build completed successfully!
    echo.
    echo Output files should be in: !PROJECT_DIR!\build\
    echo.
    echo According to the Playdate SDK documentation:
    echo https://sdk.play.date/2.0.3/Inside%%20Playdate%%20with%%20C.html
    echo.
    echo To create a .pdx file for the Playdate Simulator:
    echo   1. Copy the compiled .dll file from build\ to Source\
    echo   2. Ensure pdxinfo is in the Source directory
    echo   3. Load the .pdx bundle in Playdate Simulator
    echo.
) else (
    echo Build failed with exit code !BUILD_EXIT_CODE!
    echo.
    echo Please check the error messages above.
    echo.
    echo For help, see the official documentation:
    echo https://sdk.play.date/2.0.3/Inside%%20Playdate%%20with%%20C.html
    echo.
)

echo ========================================
pause
