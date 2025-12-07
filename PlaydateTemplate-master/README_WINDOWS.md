# Building Playdate C Project on Windows

This guide explains how to build the Playdate C project template on Windows.

## Prerequisites

1. **CMake** (3.14 or higher)
   - Download from: https://cmake.org/download/
   - Make sure to add CMake to your PATH during installation

2. **C Compiler** (choose one):
   - **MinGW-w64** (recommended for simplicity)
     - Download from: https://www.mingw-w64.org/downloads/
     - Or use MSYS2: https://www.msys2.org/
   - **Visual Studio** (with C++ build tools)
     - Download Visual Studio Community: https://visualstudio.microsoft.com/
     - Make sure to install "Desktop development with C++" workload
   - **Clang** (via LLVM)
     - Download from: https://llvm.org/builds/

3. **Playdate SDK**
   - Will be downloaded automatically by the build script, or
   - Download manually from: https://play.date/dev/
   - Extract to the `playdate` directory in this folder

## Quick Start

### Option 1: Using the Build Script (Easiest)

1. Open Command Prompt or PowerShell in the `PlaydateTemplate-master` directory
2. Run:
   ```batch
   build_playdate.bat
   ```
3. The script will:
   - Check for CMake
   - Download Playdate SDK if needed
   - Configure and build the project

### Option 2: Manual Build

1. **Download Playdate SDK**:
   - Download from: https://play.date/dev/
   - Extract the SDK to `PlaydateTemplate-master/playdate/`

2. **Create build directory**:
   ```batch
   mkdir build
   cd build
   ```

3. **Configure with CMake**:
   
   For MinGW:
   ```batch
   cmake .. -G "MinGW Makefiles"
   ```
   
   For Visual Studio:
   ```batch
   cmake .. -G "Visual Studio 17 2022" -A x64
   ```
   
   For NMake (Visual Studio Command Prompt):
   ```batch
   cmake .. -G "NMake Makefiles"
   ```

4. **Build the project**:
   ```batch
   cmake --build . --config Release
   ```

## Build Output

After building, you'll find:
- Compiled library (`.dll` on Windows) in the `build` directory
- The library needs to be copied to the `Source` directory to create a `.pdx` bundle

## Creating a .pdx Bundle

1. Copy the compiled `.dll` file from `build/` to `Source/`
2. Ensure `Source/pdxinfo` exists (it should already be there)
3. Rename the `Source` directory to `YourGame.pdx`
4. Load the `.pdx` file in Playdate Simulator

## Troubleshooting

### CMake not found
- Make sure CMake is installed and added to PATH
- Restart your terminal after installing CMake

### Compiler not found
- Install MinGW, Visual Studio, or Clang
- Make sure the compiler is in your PATH
- For Visual Studio, use the "Developer Command Prompt"

### Playdate SDK not found
- Download the SDK manually from https://play.date/dev/
- Extract it to `PlaydateTemplate-master/playdate/`
- The directory structure should be: `playdate/C_API/`, `playdate/Simulator/`, etc.

### Build errors
- Check that you have the latest Playdate SDK
- Make sure your C compiler supports C11 standard
- Check the CMake output for specific error messages

## Project Structure

```
PlaydateTemplate-master/
├── CMakeLists.txt      # CMake build configuration
├── main.c              # Main C source file
├── Source/            # Game assets and metadata
│   ├── pdxinfo       # Game metadata
│   └── main.lua      # Lua script (if using Lua)
├── build/            # Build output directory (created by CMake)
└── playdate/         # Playdate SDK (downloaded automatically)
```

## Next Steps

1. Edit `main.c` to add your game logic
2. Modify `Source/pdxinfo` with your game's information
3. Add assets to the `Source` directory
4. Build and test in Playdate Simulator

For more information, see the [Playdate SDK Documentation](https://sdk.play.date/).

