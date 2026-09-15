#!/bin/sh
# Workspace switching and window focus must work with the required
# xdotool runtime when wmctrl is not installed. wmctrl stays as a
# preferred fast path when it is available.
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Never let a test helper reach the live X session, even if a fake
# binary is bypassed by a future script change.
unset DISPLAY

state="$repo_dir/scripts/dwm-quickshell-state"

mkdir -p "$work/fake-xdotool" "$work/fake-wmctrl" "$work/empty"
cat >"$work/fake-xdotool/xdotool" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$work/xdotool.log"
EOF
cat >"$work/fake-wmctrl/wmctrl" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$work/wmctrl.log"
EOF
chmod +x "$work/fake-xdotool/xdotool" "$work/fake-wmctrl/wmctrl"
: >"$work/xdotool.log"
: >"$work/wmctrl.log"

# switch prefers wmctrl when it is available.
PATH="$work/fake-wmctrl:$work/fake-xdotool:$work/empty" /bin/sh "$state" switch 3
grep -qx '\-s 3' "$work/wmctrl.log"
test ! -s "$work/xdotool.log"

# switch falls back to xdotool without wmctrl.
: >"$work/wmctrl.log"
PATH="$work/fake-xdotool:$work/empty" /bin/sh "$state" switch 3
grep -qx 'set_desktop 3' "$work/xdotool.log"
test ! -s "$work/wmctrl.log"

# switch rejects non-numeric targets before touching any helper.
status=0
PATH="$work/fake-wmctrl:$work/fake-xdotool:$work/empty" /bin/sh "$state" switch x \
	>"$work/out" 2>"$work/err" || status=$?
test "$status" -eq 2
grep -q 'usage:' "$work/err"

# focus prefers wmctrl when it is available.
: >"$work/wmctrl.log"
: >"$work/xdotool.log"
PATH="$work/fake-wmctrl:$work/fake-xdotool:$work/empty" /bin/sh "$state" focus 0x1400003
grep -qx '\-ia 0x1400003' "$work/wmctrl.log"
test ! -s "$work/xdotool.log"

# focus falls back to xdotool raise plus focus without wmctrl.
: >"$work/wmctrl.log"
PATH="$work/fake-xdotool:$work/empty" /bin/sh "$state" focus 20971523
grep -qx 'windowraise 20971523 windowfocus 20971523' "$work/xdotool.log"
test ! -s "$work/wmctrl.log"

# focus rejects invalid targets before touching any helper.
status=0
PATH="$work/fake-wmctrl:$work/fake-xdotool:$work/empty" /bin/sh "$state" focus bogus \
	>"$work/out" 2>"$work/err" || status=$?
test "$status" -eq 2
grep -q 'usage:' "$work/err"

# Without either helper the error names the missing capability and action.
status=0
PATH="$work/empty" /bin/sh "$state" switch 1 \
	>"$work/out" 2>"$work/err" || status=$?
test "$status" -eq 127
grep -q 'xdotool' "$work/err"

status=0
PATH="$work/empty" /bin/sh "$state" focus 0x1400003 \
	>"$work/out" 2>"$work/err" || status=$?
test "$status" -eq 127
grep -q 'xdotool' "$work/err"

printf '%s\n' 'Quickshell workspace switch fallback: PASS'
