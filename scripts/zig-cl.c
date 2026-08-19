/*
 * zig-cl -- a compiler shim that lets nvim-treesitter build parsers with zig.
 *
 * nvim-treesitter `main` installs parsers through the tree-sitter CLI, which
 * builds via Rust's `cc` crate. There is no usable MSVC on this machine, so the
 * default path fails with `cl.exe ... Error: program not found`.
 *
 * Pointing CC straight at zig does not work either: the cc crate treats CC as a
 * single executable, so `CC="zig cc"` ends up running `zig -O2 ...` and zig
 * reports `unknown command: -O2`. This shim exists to be that single executable.
 *
 * It has to cope with two flag dialects:
 *
 *   - GNU style, which the cc crate emits once CC is set. Nearly everything here
 *     is already what zig wants, so the default is to pass arguments through
 *     untouched. Dropping unknown flags instead would eat `-o` and `-shared`.
 *   - MSVC style (-nologo, -LD, /Fo, -link, -out:), in case something invokes the
 *     shim the way it would invoke cl.exe.
 *
 * Windows paths also arrive with the \?\ extended-length prefix, which clang
 * rejects, so it is stripped from every argument.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <process.h>

static int eq(const char *a, const char *b) { return strcmp(a, b) == 0; }
static int pre(const char *s, const char *p) { return strncmp(s, p, strlen(p)) == 0; }

/* \?\C:\x -> C:\x ; clang cannot open the extended-length form */
static char *unprefix(char *p) { return pre(p, "\\?\\") ? p + 4 : p; }

int main(int argc, char **argv) {
    const char *zig = getenv("ZIG_EXE");
    if (!zig || !*zig) zig = "zig";

    char **out = calloc((size_t)argc + 8, sizeof(char *));
    if (!out) return 1;
    int n = 0;
    out[n++] = (char *)zig;
    out[n++] = "cc";

    for (int i = 1; i < argc; i++) {
        char *raw = argv[i];

        /* MSVC switches accept / or - interchangeably; test a normalised copy */
        char norm[32];
        const char *a = raw;
        if (raw[0] == '/') {
            snprintf(norm, sizeof norm, "-%s", raw + 1);
            a = norm;
        }

        /* --- MSVC-only noise, or things clang decides for itself --- */
        if (eq(a, "-nologo") || eq(a, "-Brepro") || eq(a, "-utf-8") ||
            eq(a, "-MD") || eq(a, "-MT") || eq(a, "-MDd") || eq(a, "-MTd") ||
            eq(a, "-W4") || eq(a, "-W3") || eq(a, "-EHsc") || eq(a, "-Zi") ||
            eq(a, "-GS-") || eq(a, "-Gy") || eq(a, "-TC") || eq(a, "-TP") ||
            eq(a, "-link")) continue;

        /* object dir / debug db / import lib: zig needs none of them */
        if (pre(a, "-Fo") || pre(a, "-Fd") || pre(a, "-IMPLIB:")) continue;

        /* --- MSVC spellings that do have a GNU equivalent --- */
        if (eq(a, "-LD") || eq(a, "-LDd")) { out[n++] = "-shared"; continue; }

        if (pre(a, "-std:")) {                       /* -std:c11 -> -std=c11 */
            char *s = malloc(strlen(a) + 2);
            if (!s) return 1;
            sprintf(s, "-std=%s", a + 5);
            out[n++] = s;
            continue;
        }

        if (pre(a, "-out:")) {                       /* -out:X -> -o X */
            out[n++] = "-o";
            out[n++] = unprefix(raw + 5);
            continue;
        }

        /* Rust triples (x86_64-pc-windows-msvc) are not zig triples. Drop the
         * vendor field and target windows-gnu, so zig uses the MinGW-w64 headers
         * and CRT it bundles -- the whole point, since there is no Windows SDK. */
        if (pre(a, "--target=") || eq(a, "-target")) {
            const char *triple = eq(a, "-target") ? (i + 1 < argc ? argv[++i] : "") : a + 9;
            if (strstr(triple, "windows")) {
                char arch[32] = {0};
                size_t k = strcspn(triple, "-");
                if (k >= sizeof arch) k = sizeof arch - 1;
                memcpy(arch, triple, k);
                char *s = malloc(strlen(arch) + 32);
                if (!s) return 1;
                sprintf(s, "--target=%s-windows-gnu", arch);
                out[n++] = s;
            }
            continue;   /* non-Windows triples: let zig pick the native target */
        }

        /* --- everything else is already GNU-style: pass it through --- */
        out[n++] = unprefix(raw);
    }
    out[n] = NULL;

    if (getenv("ZIG_CL_VERBOSE")) {
        for (int i = 0; i < n; i++) fprintf(stderr, "%s ", out[i]);
        fprintf(stderr, "\n");
    }

    return (int)_spawnvp(_P_WAIT, out[0], (const char *const *)out);
}
