#!/usr/bin/env python3
"""Bound concurrent corpus loads across research worktrees using shared flock slots.

The coordinator sets the limit from measured RSS; locks survive exec and release
on process exit. Use existing sealed observations instead of loading when possible.
"""
import fcntl
import os
from pathlib import Path
import sys
import time


def main():
    if len(sys.argv) < 2:
        raise SystemExit('usage: with-ccgbank-slot.py COMMAND [ARG ...]')
    directory = Path.home() / 'astra-wt' / '.ccgbank-slots'
    limit = int((directory / 'limit').read_text())
    if not 1 <= limit <= 59:
        raise SystemExit('invalid slot limit; coordinator must remeasure RSS')
    while True:
        for index in range(limit):
            descriptor = os.open(directory / f'{index}.lock', os.O_CREAT | os.O_RDWR, 0o600)
            try:
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                os.close(descriptor)
                continue
            os.set_inheritable(descriptor, True)
            os.execvp(sys.argv[1], sys.argv[1:])
        time.sleep(0.2)


if __name__ == '__main__':
    main()
