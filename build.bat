@echo off
REM GB Studio Build Script for Windows
REM This script builds the GB Studio application

setlocal enabledelayedexpansion

REM Get the current directory
cd /d "%~dp0"
set "PROJECT_DIR=%CD%"

REM Prevent window from closing on error
set "EXIT_CODE=0"

echo ========================================
echo GB Studio Build Script
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js 21.7.1 or higher
    pause
    exit /b 1
)

REM Display Node.js version
echo Checking Node.js version...
node --version
echo.
echo Note: npm deprecation warnings about --global/--local flags are harmless
echo and can be safely ignored. They come from npm's internal configuration.
echo.

REM Check Node version (should be 21.7.1 or higher)
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo Current Node.js version: %NODE_VERSION%
echo Recommended: v21.7.1 (see .nvmrc)
echo.

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
    echo.
)

REM Verify electron-forge is available
echo Verifying build tools...
call npm list @electron-forge/cli >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: @electron-forge/cli may not be installed correctly
    echo Attempting to install build dependencies...
    call npm install --save-dev @electron-forge/cli
)
echo.

REM Fetch submodules and dependencies
echo Fetching submodules and dependencies...
call npm run fetch-deps
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: fetch-deps failed. This may require Node.js 21.7.1 or higher.
    echo Continuing anyway...
    echo.
)

REM Function to display build output paths
goto :menu

:show_build_paths
set "ARCH=%~1"
set "ARCH_NAME=%~2"
echo.
echo ========================================
echo Build Output Locations:
echo ========================================
echo.

REM Check if out directory exists
if not exist "!PROJECT_DIR!\out" (
    echo ERROR: The 'out' directory does not exist.
    echo.
    echo This means the build did NOT complete successfully.
    echo The build process likely failed during compilation.
    echo.
    echo Please scroll up and look for error messages, especially:
    echo   - TypeScript compilation errors
    echo   - Webpack build errors
    echo   - Missing dependencies
    echo.
    echo Expected output location: !PROJECT_DIR!\out\
    echo.
    goto :eof
)

REM Check for main executable - try expected paths first
set "EXE_PATH=!PROJECT_DIR!\out\GB Studio-win32-!ARCH!\pdstudio.exe"
set "EXE_PATH_OLD=!PROJECT_DIR!\out\GB Studio-win32-!ARCH!\gb-studio.exe"
set "EXE_PATH_PD=!PROJECT_DIR!\out\PD Studio-win32-!ARCH!\pdstudio.exe"
set "FOUND_EXE=0"

if exist "!EXE_PATH!" (
    echo [MAIN EXECUTABLE]
    echo !EXE_PATH!
    echo.
    set "FOUND_EXE=1"
) else if exist "!EXE_PATH_OLD!" (
    echo [MAIN EXECUTABLE]
    echo !EXE_PATH_OLD!
    echo.
    set "FOUND_EXE=1"
) else if exist "!EXE_PATH_PD!" (
    echo [MAIN EXECUTABLE]
    echo !EXE_PATH_PD!
    echo.
    set "FOUND_EXE=1"
) else (
    echo [MAIN EXECUTABLE] - NOT FOUND
    echo Expected: !EXE_PATH!
    echo Or: !EXE_PATH_OLD!
    echo Or: !EXE_PATH_PD!
    echo.
    echo This indicates the build failed during compilation.
    echo.
    echo Searching for any executables in out directory...
    set "FOUND_ANY=0"
    for /r "!PROJECT_DIR!\out" %%f in (*.exe) do (
        echo   Found: %%f
        set "FOUND_ANY=1"
    )
    if !FOUND_ANY! EQU 0 (
        echo   No executables found - build did not complete successfully.
        echo.
        echo TROUBLESHOOTING:
        echo   1. Check the build output above for TypeScript/compilation errors
        echo   2. Ensure all dependencies are installed: npm install
        echo   3. Ensure Node.js version is 21.7.1 or higher (current: %NODE_VERSION%)
        echo   4. Try running: npm run fetch-deps
    )
    echo.
)

REM Check for Squirrel installer
set "SQUIRREL_DIR=!PROJECT_DIR!\out\make\squirrel.windows\!ARCH!"
if exist "!SQUIRREL_DIR!" (
    echo [INSTALLER]
    set "FOUND_INSTALLER=0"
    for %%f in ("!SQUIRREL_DIR!\*.exe") do (
        echo %%f
        set "FOUND_INSTALLER=1"
    )
    if !FOUND_INSTALLER! EQU 0 (
        echo   Directory exists but no installer files found.
    )
    echo.
)

REM Check for ZIP file
set "ZIP_DIR=!PROJECT_DIR!\out\make\zip\win32\!ARCH!"
if exist "!ZIP_DIR!" (
    echo [ZIP ARCHIVE]
    set "FOUND_ZIP=0"
    for %%f in ("!ZIP_DIR!\*.zip") do (
        echo %%f
        set "FOUND_ZIP=1"
    )
    if !FOUND_ZIP! EQU 0 (
        echo   Directory exists but no ZIP files found.
    )
    echo.
)

REM List all directories in out for debugging
echo [OUT DIRECTORY STRUCTURE]
echo !PROJECT_DIR!\out\
for /d %%d in ("!PROJECT_DIR!\out\*") do (
    echo   [DIR] %%d
)
echo.

echo ========================================
goto :eof

:skip_functions

:menu
REM Build options
echo ========================================
echo Build Options:
echo ========================================
echo 1. Development mode (npm start)
echo 2. Build for Windows 64-bit (npm run make:win)
echo 3. Build for Windows 32-bit (npm run make:win32)
echo 4. Build for current platform (npm run make)
echo 5. Package only (npm run package)
echo 6. Exit
echo.

set "choice="
set /p choice="Enter your choice (1-6): "

REM Remove any leading/trailing whitespace from the choice
for /f "tokens=*" %%a in ("!choice!") do set "choice=%%a"

if "!choice!"=="1" (
    echo.
    echo Starting development mode...
    call npm start
    echo.
    echo Development server stopped.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
) else if "!choice!"=="2" (
    echo.
    echo Building for Windows 64-bit...
    echo Note: Type checking is enabled. Test files are excluded during production builds.
    echo.
    echo Starting build process... This may take several minutes.
    echo Please wait, do not close this window...
    echo.
    echo Checking if 'out' directory exists before build...
    if exist "!PROJECT_DIR!\out" (
        echo   'out' directory exists
    ) else (
        echo   'out' directory does not exist (this is normal for a fresh build)
    )
    echo.
    call npm run make:win
    set "BUILD_EXIT_CODE=!ERRORLEVEL!"
    echo.
    echo ========================================
    echo Build command completed with exit code: !BUILD_EXIT_CODE!
    echo ========================================
    echo.
    echo Checking if 'out' directory exists after build...
    if exist "!PROJECT_DIR!\out" (
        echo   'out' directory exists
        echo   Listing contents of out directory:
        dir /b "!PROJECT_DIR!\out" 2>nul || echo   (empty or error listing)
        echo.
        echo   Checking for subdirectories:
        for /d %%d in ("!PROJECT_DIR!\out\*") do (
            echo     Found: %%d
        )
    ) else (
        echo   ERROR: 'out' directory was NOT created - build failed!
    )
    echo.
    echo.
    echo ========================================
    if "!BUILD_EXIT_CODE!"=="0" (
        REM Check if files were actually created
        set "HAS_OUTPUT=0"
        if exist "!PROJECT_DIR!\out\GB Studio-win32-x64\pdstudio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\GB Studio-win32-x64\gb-studio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\PD Studio-win32-x64\pdstudio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\make" set "HAS_OUTPUT=1"
        
        if !HAS_OUTPUT! EQU 0 (
            echo WARNING: Build reported success but no output files were created!
            echo This usually means the build failed during compilation.
            echo Please check the error messages above.
            echo.
        ) else (
            echo Build completed successfully!
        )
        call :show_build_paths x64 x64
    ) else (
        echo.
        echo Build failed with exit code !BUILD_EXIT_CODE!
        echo Please check the error messages above.
    )
    echo ========================================
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
) else if "!choice!"=="3" (
    echo.
    echo Building for Windows 32-bit...
    call npm run make:win32
    set "BUILD_EXIT_CODE=!ERRORLEVEL!"
    echo.
    if "!BUILD_EXIT_CODE!"=="0" (
        REM Check if files were actually created
        set "HAS_OUTPUT=0"
        if exist "!PROJECT_DIR!\out\GB Studio-win32-ia32\pdstudio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\GB Studio-win32-ia32\gb-studio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\PD Studio-win32-ia32\pdstudio.exe" set "HAS_OUTPUT=1"
        if exist "!PROJECT_DIR!\out\make" set "HAS_OUTPUT=1"
        
        if !HAS_OUTPUT! EQU 0 (
            echo WARNING: Build reported success but no output files were created!
            echo This usually means the build failed during compilation.
            echo Please check the error messages above.
            echo.
        ) else (
            echo Build completed successfully!
        )
        call :show_build_paths ia32 ia32
    ) else (
        echo.
        echo Build failed with exit code !BUILD_EXIT_CODE!
        echo Please check the error messages above.
    )
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
) else if "!choice!"=="4" (
    echo.
    echo Building for current platform...
    call npm run make
    set "BUILD_EXIT_CODE=!ERRORLEVEL!"
    echo.
    if "!BUILD_EXIT_CODE!"=="0" (
        echo Checking for output files...
        echo.
        set "HAS_OUTPUT=0"
        if exist "!PROJECT_DIR!\out\GB Studio-win32-x64\pdstudio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths x64 x64
        ) else if exist "!PROJECT_DIR!\out\GB Studio-win32-x64\gb-studio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths x64 x64
        ) else if exist "!PROJECT_DIR!\out\PD Studio-win32-x64\pdstudio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths x64 x64
        ) else if exist "!PROJECT_DIR!\out\GB Studio-win32-ia32\pdstudio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths ia32 ia32
        ) else if exist "!PROJECT_DIR!\out\GB Studio-win32-ia32\gb-studio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths ia32 ia32
        ) else if exist "!PROJECT_DIR!\out\PD Studio-win32-ia32\pdstudio.exe" (
            set "HAS_OUTPUT=1"
            call :show_build_paths ia32 ia32
        )
        
        if !HAS_OUTPUT! EQU 0 (
            echo WARNING: Build reported success but no output files were created!
            echo This usually means the build failed during compilation.
            echo Please check the error messages above.
            echo.
            echo Expected output location: !PROJECT_DIR!\out\
        )
    ) else (
        echo.
        echo Build failed with exit code !BUILD_EXIT_CODE!
        echo Please check the error messages above.
    )
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
) else if "!choice!"=="5" (
    echo.
    echo Packaging application...
    call npm run package
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo Package completed successfully!
        echo.
        echo Packaged application location:
        if exist "%PROJECT_DIR%\out\GB Studio-win32-x64\pdstudio.exe" (
            echo %PROJECT_DIR%\out\GB Studio-win32-x64\pdstudio.exe
        ) else if exist "%PROJECT_DIR%\out\GB Studio-win32-x64\gb-studio.exe" (
            echo %PROJECT_DIR%\out\GB Studio-win32-x64\gb-studio.exe
        ) else if exist "%PROJECT_DIR%\out\PD Studio-win32-x64\pdstudio.exe" (
            echo %PROJECT_DIR%\out\PD Studio-win32-x64\pdstudio.exe
        ) else if exist "%PROJECT_DIR%\out\GB Studio-win32-ia32\pdstudio.exe" (
            echo %PROJECT_DIR%\out\GB Studio-win32-ia32\pdstudio.exe
        ) else if exist "%PROJECT_DIR%\out\GB Studio-win32-ia32\gb-studio.exe" (
            echo %PROJECT_DIR%\out\GB Studio-win32-ia32\gb-studio.exe
        ) else if exist "%PROJECT_DIR%\out\PD Studio-win32-ia32\pdstudio.exe" (
            echo %PROJECT_DIR%\out\PD Studio-win32-ia32\pdstudio.exe
        ) else (
            echo %PROJECT_DIR%\out\
        )
    ) else (
        echo.
        echo Package failed!
    )
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
) else if "!choice!"=="6" (
    echo Exiting...
    exit /b 0
) else (
    echo Invalid choice!
    echo.
    echo Press any key to return to the menu...
    pause >nul
    goto :menu
)

