# FlightSearch

Swift package and example iOS app for searching a flight and keeping that flight on the Lock Screen and Dynamic Island. Search stays on the device. There is no booking backend yet. Live Activity updates can be driven from the simulator before a push certificate or server exists.

## What is in the repo

| Piece | Role |
| --- | --- |
| `FlightSearchKit` | SwiftUI search screen, airport catalog, route checks, and the ActivityKit client. |
| `FlightActivityAttributes` | Shared flight model. The app and the widget both link this, so the widget does not pull in Core Data or the search UI. |
| `FlightSearchExample` | iOS app that embeds `FlightSearchView` and the Live Activity extension. Bundle id `com.learning.FlightSearchExample`. |
| `FlightSearchExample/LiveActivityPayloads` | `.apns` files for scheduled, boarding, departed, in flight, delayed, landed, and cancelled. |

Platforms for the package are iOS 17 and macOS 14. The example app is built for the current iOS simulator.

## Search

`FlightSearchView` is the public screen. It offers one way, return, and multi-city. The last trip type and the last origin and destination are stored with Core Data and restored after the app is killed.

Airports are a local mock catalog: DXB, LHR, JFK, BOM, SIN, DOH, SYD, FRA, LAX, and DEL. The picker filters by city, airport name, and IATA code. Search validates the route and confirms it. It does not call a server.

## Live Activity

After a route is confirmed, **Track on Lock Screen** starts one flight activity. Phase buttons on that card move it through scheduled, boarding, departed, in flight, delayed, landed, and cancelled. Landed and cancelled leave the Lock Screen after about 15 minutes.

The widget shows the flight number, both airports, gate, terminal, delay, and progress. Operational status only: no passenger name, PNR, or seat.

### Simulator, before a `.p8` key

Run **FlightSearchExample** once so it can receive the dropped files. Then drag the files in `FlightSearchExample/LiveActivityPayloads` onto the Simulator in filename order, or push one with:

```bash
xcrun simctl push booted com.learning.FlightSearchExample FlightSearchExample/LiveActivityPayloads/01-start-scheduled.apns
```

`01-start-scheduled.apns` starts **FS412**, Dubai to London. The later files update that activity. `06-landed` and `07-cancelled` are alternate endings, so drop only one of them. If a later session ignores a file, refresh the timestamps:

```bash
python3 FlightSearchExample/LiveActivityPayloads/stamp-payloads.py
```

A push token is collected only after the app has the Push Notifications capability. The development `aps-environment` entitlement is already on the example app so the simulator can accept these files. The `.p8` key and the server are the next step, not part of this tree.

## iPhone 18

Compact Dynamic Island, the expanded flight card, and the Lock Screen for FS541 Doha to Mumbai, delayed 40 minutes.

<p>
  <img src="FlightSearchExample/ScreenShots/IPhone18/Screenshot%202026-11-15%20at%2022.03.38.png" width="240" alt="iPhone 18 compact Dynamic Island showing FS541 delayed 40 minutes">
  <img src="FlightSearchExample/ScreenShots/IPhone18/Screenshot%202026-11-15%20at%2022.03.25.png" width="240" alt="iPhone 18 expanded Live Activity for FS541 Doha to Mumbai">
  <img src="FlightSearchExample/ScreenShots/IPhone18/Screenshot%202026-11-15%20at%2022.03.53.png" width="240" alt="iPhone 18 Lock Screen Live Activity for FS541">
</p>

## iPhone Duo

The same activity on the cover screen and the inner display for FS556 Mumbai to Singapore, in flight.

<p>
  <img src="FlightSearchExample/ScreenShots/Duo/Screenshot%202026-11-15%20at%2022.04.46.png" width="240" alt="iPhone Duo cover screen with the compact Live Activity">
  <img src="FlightSearchExample/ScreenShots/Duo/Screenshot%202026-11-15%20at%2022.04.03.png" width="360" alt="iPhone Duo expanded Live Activity on the cover screen">
  <img src="FlightSearchExample/ScreenShots/Duo/Screenshot%202026-11-15%20at%2022.04.41.png" width="240" alt="iPhone Duo cover screen home with FS556 in flight">
  <img src="FlightSearchExample/ScreenShots/Duo/Screenshot%202026-11-15%20at%2022.04.26.png" width="240" alt="iPhone Duo inner Lock Screen Live Activity for FS556">
</p>
