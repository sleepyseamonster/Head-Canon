#!/bin/sh

set -eu

warning_threshold_bytes=$((10 * 1024 * 1024 * 1024))
blocking_threshold_bytes=$((2 * 1024 * 1024 * 1024))

human_size() {
    bytes="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$bytes"
        return
    fi

    awk -v bytes="$bytes" '
        function human(x) {
            split("B KiB MiB GiB TiB", units, " ")
            unit = 1
            while (x >= 1024 && unit < 5) {
                x /= 1024
                unit += 1
            }
            if (unit == 1) {
                return sprintf("%.0f %s", x, units[unit])
            }
            return sprintf("%.1f %s", x, units[unit])
        }
        BEGIN { print human(bytes) }
    '
}

report_size() {
    target="$1"
    label="$2"
    if [ -e "$target" ]; then
        size="$(du -sh "$target" 2>/dev/null | awk '{print $1}')"
    else
        size="Missing"
    fi
    printf '%-42s %s\n' "$label" "$size"
}

cache_size() {
    target="$1"
    if [ -e "$target" ]; then
        du -sh "$target" 2>/dev/null | awk '{print $1}'
    else
        printf 'Missing'
    fi
}

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
headcanon_support="$HOME/Library/Application Support/HeadCanon"
headcanon_tmp="$TMPDIR/HeadCanon"
headcanon_cache="$HOME/Library/Caches/HeadCanon"
headcanon_reserve="$HOME/Library/Caches/HeadCanon/DiskReserve/headcanon-disk-reserve.bin"

available_kb="$(df -kP "$TMPDIR" | awk 'NR==2 {print $4}')"
available_bytes=$((available_kb * 1024))

if [ "$available_bytes" -lt "$blocking_threshold_bytes" ]; then
    threshold_status="BLOCKED"
elif [ "$available_bytes" -lt "$warning_threshold_bytes" ]; then
    threshold_status="LOW"
else
    threshold_status="HEALTHY"
fi

printf 'Head Canon Disk Health\n'
printf 'Repo: %s\n\n' "$repo_root"

printf 'Thresholds\n'
printf '  Warning below: %s\n' "$(human_size "$warning_threshold_bytes")"
printf '  Block below:   %s\n' "$(human_size "$blocking_threshold_bytes")"
printf '  Current free:  %s\n' "$(human_size "$available_bytes")"
printf '  Status:        %s\n\n' "$threshold_status"

printf 'Filesystem Overview\n'
df -h / "$HOME" "$TMPDIR"
printf '\n'

printf 'Head Canon Sizes\n'
report_size "$headcanon_tmp" '$TMPDIR/HeadCanon'
report_size "$headcanon_support" '~/Library/Application Support/HeadCanon'
report_size "$headcanon_cache" '~/Library/Caches/HeadCanon'
report_size "$headcanon_reserve" 'Head Canon reserve file'
report_size "$repo_root/.build" 'Repo .build'
report_size "$repo_root/dist" 'Repo dist'
printf '\n'

printf 'Cache Candidates\n'
for path in \
    "$HOME/Library/Caches" \
    "$HOME/Library/Caches/Homebrew" \
    "$HOME/Library/Caches/pip" \
    "$HOME/Library/Caches/ms-playwright" \
    "$HOME/Library/Caches/ms-playwright-go" \
    "$HOME/.npm/_cacache" \
    "$HOME/.npm/_npx" \
    "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
do
    printf '%-42s %s\n' "$path" "$(cache_size "$path")"
done
printf '\n'

printf 'Largest Top-Level Cache Folders\n'
if [ -d "$HOME/Library/Caches" ]; then
    du -sh "$HOME/Library/Caches"/* 2>/dev/null | sort -hr | head -n 15
else
    printf 'No ~/Library/Caches directory found.\n'
fi
