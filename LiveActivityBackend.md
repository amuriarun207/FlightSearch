# Live Activity payload from the backend

The backend sends one APNs request per status change. The HTTP headers stay the same. The JSON body changes with the event.

## Headers

- `apns-topic`: `com.learning.FlightSearchExample.push-type.liveactivity`
- `apns-push-type`: `liveactivity`
- `apns-priority`: `10`
- `authorization`: bearer token from the `.p8` key

Post to `https://api.push.apple.com/3/device/<token>`.

## Start

Start uses the push-to-start token. `attributes` are fixed for that flight. `content-state` is the first status.

```json
{
  "aps": {
    "timestamp": 1794761782,
    "event": "start",
    "attributes-type": "FlightActivityAttributes",
    "attributes": {
      "flightNumber": "FS412",
      "originCode": "DXB",
      "originCity": "Dubai",
      "destinationCode": "LHR",
      "destinationCity": "London",
      "scheduledDeparture": 1795000000,
      "scheduledArrival": 1795021600
    },
    "content-state": {
      "phase": "scheduled",
      "gate": "A12",
      "terminal": "3",
      "delayMinutes": 0,
      "progress": 0
    },
    "alert": {
      "title": "FS412 scheduled",
      "body": "Dubai to London. Gate A12, Terminal 3."
    }
  }
}
```

## Update

Update uses the activity push token. Send only the new `content-state`. `phase` is `scheduled`, `boarding`, `departed`, `inFlight`, `delayed`, `landed`, or `cancelled`. `progress` is `0` to `1`. Dates are UNIX seconds.

```json
{
  "aps": {
    "timestamp": 1794761842,
    "event": "update",
    "content-state": {
      "phase": "inFlight",
      "gate": "A12",
      "terminal": "3",
      "delayMinutes": 0,
      "progress": 0.75
    },
    "alert": {
      "title": "FS412 is in the air",
      "body": "Dubai to London."
    }
  }
}
```

## End

End is the same shape with `"event": "end"` and a `dismissal-date` about 15 minutes later. Use it for landed or cancelled.

```json
{
  "aps": {
    "timestamp": 1794761902,
    "event": "end",
    "dismissal-date": 1794762802,
    "content-state": {
      "phase": "landed",
      "gate": "C18",
      "terminal": "5",
      "delayMinutes": 0,
      "progress": 1
    },
    "alert": {
      "title": "FS412 landed",
      "body": "Arrival gate C18, Terminal 5."
    }
  }
}
```

Each `timestamp` must be later than the previous one. `Simulator Target Bundle` is only for the simulator `.apns` files. Do not send that key to APNs.
