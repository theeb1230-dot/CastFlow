# Android Wi-Fi Direct adapter

CastFlow uses Android's native `WifiP2pManager` through a Flutter `MethodChannel`.

## Exposed operations

- detect Wi-Fi Direct support
- request runtime permission
- discover nearby P2P peers
- list peers
- connect to a peer by device address
- create a P2P group
- remove a P2P group
- read group-owner connection information

## Permissions

Android 13+ uses `NEARBY_WIFI_DEVICES`.

Android 12 and older use `ACCESS_FINE_LOCATION` for Wi-Fi Direct discovery. The manifest limits this legacy permission to API 32.

## Role in CastFlow

Wi-Fi Direct provides a local IP network between Android mobile and Android/Google TV devices. Once the group is formed, CastFlow's existing mDNS, TCP signaling and WebRTC layers operate over that local network.

This adapter does not replace WebRTC and does not send video itself.
