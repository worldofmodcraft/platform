#!/usr/bin/env bash
# Task 049 (Q6): did the task log get a new dated entry?   See docs/manager/OPERATIONS.md.
#   check-log-entry.sh count <task-file>                 prints the number of dated log entries
#   check-log-entry.sh check <task-file> <baseline>      exit 0 only if count > baseline AND the last dated entry has a
#                                                        valid date that is not in the future
# Exit 1 = no new entry; exit 2 = usage error, unreadable file, or no log section (never "zero entries, fine").
# A dated entry is a line matching ^- 20YY-MM-DD after the line "# Task NNN log" (else the first "# Task...log" line).
set -u
die() { echo "check-log-entry: $*" >&2; exit 2; }
[ $# -ge 2 ] || die "usage: check-log-entry.sh count <task-file> | check <task-file> <baseline>"
mode=$1; file=$2
case "$mode" in count) [ $# -eq 2 ] || die "usage: count <task-file>";; check) [ $# -eq 3 ] || die "usage: check <task-file> <baseline>";; *) die "unknown mode '$mode'";; esac
[ -f "$file" ] && [ -r "$file" ] || die "cannot read task file '$file'" # CHECK:missing-file

# entries: print the dated lines of the log section; fails (status 3) when there is no log section.
entries() {
  awk '
    BEGIN { start = 0 }
    /^# Task [0-9A-Za-z]+ log/ { if (!exact) { exact = NR } }
    /^# Task.*log/ { if (!loose) { loose = NR } }
    { lines[NR] = $0 }
    END {
      start = exact ? exact : loose
      if (!start) exit 3
      for (i = start + 1; i <= NR; i++) if (lines[i] ~ /^- 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) print lines[i]  # CHECK:dated-regex
    }' "$file"
}
list=$(entries); rc=$?
[ "$rc" -ne 3 ] || die "'$file' has no log section ('# Task NNN log'); treating that as a failure, not as zero entries"
[ "$rc" -eq 0 ] || die "could not read the log of '$file'"
if [ -n "$list" ]; then n=$(printf '%s\n' "$list" | wc -l); else n=0; fi
n=$((n - 0)) # CHECK:count-offset

if [ "$mode" = count ]; then echo "$n"; exit 0; fi

baseline=$3
case "$baseline" in ''|*[!0-9]*) die "baseline must be a non-negative integer, got '$baseline'";; esac
[ "$n" -gt "$baseline" ] || { echo "check-log-entry: no new dated entry in '$file' (count $n, baseline $baseline)" >&2; exit 1; } # CHECK:baseline
last=$(printf '%s\n' "$list" | grep -E '^- 20[0-9]{2}-[0-9]{2}-[0-9]{2}' | tail -n 1 | cut -c3-12) # the date is read only from a strictly dated line
norm=$(date -d "$last" +%F 2>/dev/null) && [ "$norm" = "$last" ] || { echo "check-log-entry: last entry date '$last' is not a valid date" >&2; exit 1; } # CHECK:validdate
today=$(date +%F)
[ "$last" \> "$today" ] && { echo "check-log-entry: last entry is dated $last, in the future (today is $today)" >&2; exit 1; } # CHECK:future
exit 0
