@SetLocal
@Echo Off
REM Helpful: https://docs.bazel.build/versions/master/user-manual.html
REM clang-cl.exe info: https://github.com/bazelbuild/bazel/pull/6553#issue-226949824
REM Interesting random discussion: https://news.ycombinator.com/item?id=18445211

If "" == "%PYTHON_BIN_PATH%" For /F "usebackq delims=" %%f In (`Where python`  ) Do Set "PYTHON_BIN_PATH=%%~f"
If Not Exist "%PYTHON_BIN_PATH%" (Echo Invalid PYTHON_BIN_PATH = "%PYTHON_BIN_PATH%" 1>&2 && GoTo :EOF)
If     Exist "%PYTHON_BIN_PATH%\..\zlib1.dll" (Echo This script has not been tested against the MSYS2 versions of Python. Please use a native Windows version of Python instead. 1>&2 && GoTo :EOF)

If ""     ==   "%BAZEL_LLVM%"       For /F "usebackq delims=" %%f In (`Where clang-cl`) Do Set "BAZEL_LLVM=%%~dpf.."
For %%f  In   ("%BAZEL_LLVM%") Do   Set "BAZEL_LLVM=%%~dpnxf"
If Not Exist   "%BAZEL_LLVM%"       (Echo Invalid BAZEL_LLVM      = "%BAZEL_LLVM%"      1>&2 && GoTo :EOF)

REM To find bash.exe, we search for sh.exe beside it, because WSL also provides a bash.exe that we don't want.
If ""     ==   "%BAZEL_SH%"         For /F "usebackq delims=" %%f In (`Where sh.exe`  ) Do Set "BAZEL_SH=%%~dpfbash.exe"
If Not Exist   "%BAZEL_SH%"         (Echo Invalid BAZEL_SH        = "%BAZEL_SH%"        1>&2 && GoTo :EOF)

If ""     ==   "%BAZEL_VS%"         For /D %%f In ("%ProgramFiles(x86)%\Microsoft Visual Studio\2019\*") Do Set "BAZEL_VS=%%~f"
If Not Exist   "%BAZEL_VS%"         (Echo Invalid BAZEL_VS        = "%BAZEL_VS%"        1>&2 && GoTo :EOF)

If "" == "%USE_CLANG_CL%" Set "USE_CLANG_CL=1"

REM Set CC=clang
REM For MinGW, we need: --cpu=x64_windows --compiler=mingw-gcc --glibc=mingw
REM For Clang, we're supposed to need:  --extra_toolchains=@local_config_cc//:cc-toolchain-x64_windows-clang-cl --extra_execution_platforms=//:x64_windows-clang-cl

REM Note that BAZEL_DIR is only for our own here here; it's not used by Bazel itself.
Set "BAZEL_DIR=%BAZEL_LLVM%\..\.."
For /D %%f In ("%BAZEL_DIR%") Do Set "BAZEL_DIR=%%~dpnxf"
If Not "\"  == "%BAZEL_DIR:~-1%" Set "BAZEL_DIR=%BAZEL_DIR%\"

REM --subcommands=pretty_print is useful
REM "%BAZEL_DIR%bazel" clean --expunge
REM "%BAZEL_DIR%bazel" query "kind('rule', deps(deps(//:ray_pkg) intersect //:*, 1) except(//:* union @plasma//:*))" --order_output full
"%BAZEL_DIR%bazel" build "//:ray_pkg" %*
@EndLocal
