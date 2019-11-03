#!/usr/bin/env bash
: '" WINDOWS BATCH/BASH HYBRID FILE
@ 1>&2 echo ^^ Ignore the above error about the "#!" shebang.
@sh "%~dpnx0" %*
@GoTo :EOF
"'

set -eu
if [ -n "${BASH_VERSION+x}" ]; then
	set -o pipefail
fi

# WARNING: Do NOT try to simplify this file (e.g. the '&&'s) unless you know why each complexity is there in the first place.
# This file is rather complicated for many reasons, including:
# - Process spawns (pipelines, subshells, subprocesses, etc.) have noticeable lags on MSYS2, so we try to stay in the current shell wherever possible.
# - Bash error-handling behavior is extremely counterintuitive (whether with or without set -e), and a correct script ends up being quite convoluted.
# - Various MSYS2 idiosyncracies
# - Modularity concerns (e.g. avoiding namespace pollution if this file is included in another file)
# - General portability concerns (although somewhat unimportant here)

main() {
	if [ -z "${USE_CLANG_CL+x}" ]; then  # If USE_CLANG_CL is unset, then set it ourselves
		export USE_CLANG_CL=1
	fi
	local NEWLINE='
'
	local mingw_package_prefix="mingw-w64-x86_64-"
	if [ -z "${MINGW_DIR+x}" ]; then local MINGW_DIR="/mingw64"; fi
	if [ "${MSYSTEM_CARCH-}" = "i686" ]; then
		mingw_package_prefix="mingw-w32-i686-"
		if [ -z "${MINGW_DIR+x}" ]; then local MINGW_DIR="/mingw32"; fi
	fi
	if [ ! "${OSTYPE-}" = "msys" ] || [ ! -f "/usr/bin/msys-2.0.dll" ] || ! 1>&- command -v cygpath; then
		if [ "${OSTYPE-}" = "linux-gnu" ] && 1>&- command -v wslpath; then
			1>&2 echo "error: you appear to be running in WSL (OSTYPE=\"${OSTYPE-}\"), but this script requires Bash from MSYS2"
		else
			1>&2 echo "error: expected MSYS2 environment (detected OSTYPE=\"${OSTYPE-}\")"
		fi
		return 1
	fi && if ! 1>&- command -v clang-cl && ! pacman -Qo "${MINGW_DIR}/bin/clang-cl.exe"; then
		pacman -S --needed "${mingw_package_prefix}clang"
	fi && {
		# Detect native Windows Python installations from the registry (MSYS2 versions aren't the same)
		local latest_python_version="" latest_python_version_name="" latest_python_prefix=""
		local f && for f in /proc/registry/HKEY_CURRENT_USER/SOFTWARE/Python/PythonCore/* /proc/registry/HKEY_LOCAL_MACHINE/SOFTWARE/Python/PythonCore/*; do
			if [ ! -d "$f" ] || [ ! -f "$f/InstallPath/@" ]; then
				continue
			fi
			local version_name="${f##*/}"
			local version_sortable="${version_name##* }"
			case "${version_sortable}" in  # Make sure minor version has 2 digits to avoid breakage later
				*[0-9].[0-9]) version_sortable="${version_sortable%.*}.0${version_sortable##*.}";;
				*) ;;
			esac
			case "${version_sortable}" in  # Make sure major digit has 2 digits to avoid breakage later
				[0-9].*) version_sortable="0${version_sortable%%.*}.${version_sortable#*.}";;
				*) ;;
			esac
			if [ "${version_sortable}" ]; then
				version_sortable="${version_sortable}"
			fi
			if [ -z "${latest_python_version}" ] || [ "${latest_python_version}" \< "${version_sortable}" ]; then
				latest_python_version="${version_sortable}"
				latest_python_version_name="${version_name}"
				local line="" && while read -r line || [ -n "${line}" ]; do
					latest_python_prefix="${line}\\"
				done < "$f/InstallPath/@"
			fi
		done
		local latest_python_major_version="${latest_python_version_name%%.*}"
		local converted_paths && converted_paths="$(cygpath -w -- "/" "${MINGW_DIR}" && { cygpath -w -F 42 || cygpath -w -F 38; })${NEWLINE}"
		local          rootdir="${converted_paths%%${NEWLINE}*}"; converted_paths="${converted_paths#*${NEWLINE}}"
		local         mingwdir="${converted_paths%%${NEWLINE}*}"; converted_paths="${converted_paths#*${NEWLINE}}"
		local vs_progfiles_dir="${converted_paths%%${NEWLINE}*}"; converted_paths="${converted_paths#*${NEWLINE}}"
		local latest_vsdir="" vsroot="${vs_progfiles_dir}\\Microsoft Visual Studio"
		local vsdir && for vsdir in "${vsroot}"/20*/; do
			vsdir="${vsdir%/}"
			vsdir="${vsroot}\\${vsdir##*/}"
			for vs_version_dir in "${vsdir}"/*/; do
				vs_version_dir="${vs_version_dir%/}"
				if [ -d "${vs_version_dir}" ]; then
					latest_vsdir="${vsdir}\\${vs_version_dir##*/}"
				fi
			done
		done
		if [ -n "${rootdir}" ]; then  # Make sure that we use the Bash from the current installation regardless of what's in PATH
			export BAZEL_SH="${rootdir}\\usr\\bin\\bash.exe"
		fi
		if false && [ -z "${BAZEL_VS+x}" ] && [ -d "${latest_vsdir}" ]; then  # Not necessary since it's auto-detected properly
			export BAZEL_VS="${latest_vsdir}"
		fi
		if [ "${USE_CLANG_CL}" = 1 ] && [ -z "${BAZEL_LLVM+x}" ] && [ -x "${mingwdir}/bin/clang-cl.exe" ]; then
			export BAZEL_LLVM="${mingwdir}"
		fi
		if [ -z "${PYTHON_BIN_PATH+x}" ] && [ -n "${latest_python_prefix}" ]; then
			export PYTHON_BIN_PATH="${latest_python_prefix}python.exe"
			declare -x "PYTHON${latest_python_major_version}_BIN_PATH=${PYTHON_BIN_PATH}"
		fi
		local new_path; new_path="$(cygpath -u -- "${latest_python_prefix%\\}"):${PATH}:$(cygpath -u -- "${rootdir%\\*\\}")" || true

		local tty="" && read -s -dc -p $'\E[>c' tty < /dev/tty && tty="${tty##$'\E'[>}"
		if [ "${tty}" = "${tty#67;}" ] && [ -t 0 ] && [ -t 1 ]; then  # Use winpty if we're not on ConHost and winpty will proxy for us, since it supports proper coloring and whatnot
			MSYS2_ARG_CONV_EXCL="*" PATH="${new_path}" exec /usr/bin/winpty bazel "$@"
		else
			MSYS2_ARG_CONV_EXCL="*" PATH="${new_path}" exec                 bazel "$@"
		fi
	}
}

main "$@"
