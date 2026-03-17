#!/bin/bash
# List all configured domain names with root directories and SSL status

COL0=4    # NO.
COL1=40   # DOMAIN
COL2=55   # ROOT
COL3=5    # SSL
COL4=40   # CONFIG

sep() {
    printf '+%s+%s+%s+%s+%s+\n' \
        "$(printf '%0.s-' $(seq 1 $((COL0+2))))" \
        "$(printf '%0.s-' $(seq 1 $((COL1+2))))" \
        "$(printf '%0.s-' $(seq 1 $((COL2+2))))" \
        "$(printf '%0.s-' $(seq 1 $((COL3+2))))" \
        "$(printf '%0.s-' $(seq 1 $((COL4+2))))"
}

sep
printf "\033[1m| %-${COL0}s | %-${COL1}s | %-${COL2}s | %-${COL3}s | %-${COL4}s |\033[0m\n" \
    "NO." "DOMAIN" "ROOT" "SSL" "CONFIG"
sep

{
    for conf in /etc/nginx/sites-enabled/*; do
        [ -f "$conf" ] || continue
        awk -v conf="$(basename "$conf")" '
        BEGIN { in_server=0; depth=0 }
        {
            opens=0; closes=0
            for (i=1; i<=length($0); i++) {
                c = substr($0, i, 1)
                if (c == "{") opens++
                if (c == "}") closes++
            }
        }
        !in_server && /^[[:space:]]*server[[:space:]]*\{/ {
            in_server=1; depth=opens-closes
            names=""; root=""; ssl="No"
            next
        }
        in_server {
            depth += opens - closes
            if (depth <= 0) {
                if (names != "") {
                    n = split(names, arr, /[[:space:]]+/)
                    for (i=1; i<=n; i++) {
                        d = arr[i]
                        if (d != "" && d != "_" && d != "localhost" && d != "default_server")
                            printf "%s\t%s\t%s\t%s\n", d, (root==""?"(none)":root), ssl, conf
                    }
                }
                in_server=0; depth=0
            } else {
                if (/^[[:space:]]*server_name[[:space:]]/) {
                    sub(/^[[:space:]]*server_name[[:space:]]+/, "")
                    sub(/[[:space:]]*;.*$/, "")
                    names=$0
                }
                if (/^[[:space:]]*root[[:space:]]/ && root=="") {
                    sub(/^[[:space:]]*root[[:space:]]+/, "")
                    sub(/[[:space:]]*;.*$/, "")
                    root=$0
                }
                if (/ssl_certificate[^_[:alnum:]]/) ssl="Yes"
            }
        }
        ' "$conf"
    done
} | sort -u | awk \
    -v c0="$COL0" -v c1="$COL1" -v c2="$COL2" -v c3="$COL3" -v c4="$COL4" \
    'BEGIN {
        FS  = "\t"
        CA  = "\033[0m"     # default (odd rows)
        CB  = "\033[0;36m"  # cyan    (even rows)
        RST = "\033[0m"
    }
    {
        lines[NR] = $0
        dom[NR]   = $1
        rt[NR]    = $2
        if ($2 != "(none)") has_root[$1] = 1
    }
    END {
        row = 0
        for (i=1; i<=NR; i++) {
            if (rt[i] == "(none)" && has_root[dom[i]]) continue
            row++
            n = split(lines[i], f, "\t")
            clr = (row % 2 == 1) ? CA : CB
            printf "%s| %-" c0 "s | %-" c1 "s | %-" c2 "s | %-" c3 "s | %-" c4 "s |%s\n",
                clr, row".", f[1], f[2], f[3], f[4], RST
        }
    }'

sep
