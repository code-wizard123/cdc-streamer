#!/bin/sh
set -eu

if ! getent passwd "$JUPYTER_UID" >/dev/null; then
    printf 'notebook:x:%s:%s:Notebook user:%s:/bin/sh\n' "$JUPYTER_UID" "$JUPYTER_GID" "$HOME" >> /etc/passwd
fi

if ! getent group "$JUPYTER_GID" >/dev/null; then
    printf 'notebook:x:%s:\n' "$JUPYTER_GID" >> /etc/group
fi

exec setpriv --no-new-privs --bounding-set=-all --reuid="$JUPYTER_UID" --regid="$JUPYTER_GID" --clear-groups "$@"
