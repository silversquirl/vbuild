# vbuild

vbuild is a very simple build system written in POSIX-compliant shell.
It provides shell functions for resolving dependencies and registering build rules, allowing you to write your specific build scripts as shell functions, separate scripts or even compiled binaries.
The entire build system is around 100 lines of code, although for simple builds the configuration may be longer than for systems such as Make.

Where vbuild really shines is in flexibility and portability.
Because the entire system is written in shell, it is portable to any any UNIX system in existence, as well as many non-UNIX systems such as Windows (with Cygwin, etc.) or Plan9.
This language choice also provides a lot of flexibility: because the configuration is written in shell, you can do anything you could in a regular shell script, including calling out to other programs.
