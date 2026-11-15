#!/usr/bin/env python3
"""Rewrite simulator Live Activity timestamps so a drop is accepted.

ActivityKit ignores a push whose timestamp is more than an hour old, and it
ignores any push older than the last one applied. Run this, then drag the
.apns files onto the Simulator in filename order.
"""

import json
import time
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent


def main() -> None:
    files = sorted(DIRECTORY.glob("*.apns"))
    base = int(time.time())
    for index, path in enumerate(files):
        payload = json.loads(path.read_text())
        aps = payload["aps"]
        stamp = base + index * 60
        aps["timestamp"] = stamp
        if aps.get("event") == "end":
            aps["dismissal-date"] = stamp + 15 * 60
        path.write_text(json.dumps(payload, indent=2) + "\n")
        print(f"{path.name}  timestamp={stamp}  event={aps.get('event')}")


if __name__ == "__main__":
    main()
