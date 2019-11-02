#ifndef UNISTD_H
#define UNISTD_H

extern char *optarg;
extern int optind, opterr, optopt;
int getopt(int nargc, char *const nargv[], const char *ostr);

#if 0
#include "../../src/Win32_Interop/Win32_FDAPI.h"
#define close(...) FDAPI_close(__VA_ARGS__)
#else
#include <io.h>  // open/read/write/close
#ifndef EXTERN_C
#ifdef __cplusplus
#define EXTERN_C extern "C"
#else
#define EXTERN_C
#endif
#endif
#ifndef DECLSPEC_IMPORT
#define DECLSPEC_IMPORT __declspec(dllimport)
#endif
#ifndef WINBASEAPI
#define WINBASEAPI DECLSPEC_IMPORT
#endif
#ifndef WINAPI
#define WINAPI __stdcall
#endif
typedef int BOOL;
typedef void *HANDLE;
typedef unsigned long DWORD;
#ifdef _WIN64
typedef unsigned long long UINT_PTR;
typedef unsigned long long ULONG_PTR;
typedef long long ssize_t;
#else
typedef unsigned int UINT_PTR;
typedef unsigned long ULONG_PTR;
typedef int ssize_t;
#endif
typedef int pid_t /* technically unsigned on Windows, but no practical concern */;
typedef ULONG_PTR SIZE_T;
EXTERN_C WINBASEAPI void WINAPI Sleep(DWORD dwMilliseconds);
#endif

typedef unsigned int useconds_t;
int usleep(useconds_t usec);

#endif /* UNISTD_H */
