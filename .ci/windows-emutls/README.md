# Windows emutls prototype

This manually triggered CI experiment compares unmodified Windows Cling with
the `cling-windows-emutls` prototype branch.

The passing test covers constant-initialized `thread_local` variables across
multiple threads and a basic two-thread function-local static check. It does
not establish complete guard correctness; higher-concurrency local runs have
been intermittent. The prototype builds compiler-rt's `emutls.c` as a separate
`/GS-` archive and links it into the Cling driver. This is diagnostic
integration, not a proposed runtime ownership model.

Dynamic `thread_local` initialization and thread-exit TLS destructors are not
covered. They remain unresolved in this prototype.

Each matrix job retains a text-only transcript for 90 days and a runnable
Release bundle for 30 days. The bundle includes Clang resource headers, Cling
headers, the generated option header, and a wrapper that replaces the
non-portable build-time Cling include path.
