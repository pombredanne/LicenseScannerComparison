# Generated Output
```
$ cat _output/time-1.7.tar.gz/debian-licensecheck/output
/time-1.7.tar.gz/port.h	UNKNOWN
/time-1.7.tar.gz/resuse.h	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/version.c	UNKNOWN
/time-1.7.tar.gz/time.c	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/getopt1.c	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/resuse.c	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/getpagesize.h	UNKNOWN
/time-1.7.tar.gz/error.c	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/getopt.h	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/getopt.c	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/texinfo.tex	GPL (v2 or later) (with incorrect FSF address)
/time-1.7.tar.gz/wait.h	GPL (v2 or later) (with incorrect FSF address)
```
## Expected convertet output
```
"port.h";"NOASSERTION";
"resuse.h";"GPL-2.0-only,GPL-2.0-or-later";
[...]
```

## Mapping
| from                | to                              |
|---------------------|---------------------------------|
| `GPL (v2 or later)` | `GPL-2.0-only,GPL-2.0-or-later` |
| `UNKNOWN`           | `NOASSERTION`                   |
