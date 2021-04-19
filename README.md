<img src="https://user-images.githubusercontent.com/6486741/115228357-8f8b9800-a109-11eb-98ca-0bd4ada84b20.png" width=100>

# PlaneTalk ![](https://img.shields.io/badge/iOS-Swift-green)

PlaneTalk is an iOS app written in Swift which lets you send messages to other devices connected to the same Wi-fi-Hotspot network.
It's suitable in places where there is no internet connection like airplanes (hence the name PlaneTalk 😃).

The core functionalities are all built around some TCP and UDP's `syscall` and uses `kevent` as event notification system.
The UDP protocol is only being used for discovery's purposes whereas the TCP protocol is being used to connect and communicate with the server.

## Preview

| Sample 1 | Sample 2 | Sample 3 |
| ------------- | ------------- | ------------- |
| <img width=150 src="https://user-images.githubusercontent.com/6486741/115229482-04130680-a10b-11eb-8c1c-e373cf2e8603.png">  | <img width=150 src="https://user-images.githubusercontent.com/6486741/115229496-07a68d80-a10b-11eb-9c07-12645ebf09c6.PNG">  | <img width=150 src="https://user-images.githubusercontent.com/6486741/115229668-391f5900-a10b-11eb-9b77-3739fe9a8480.PNG"> |

## How it works
When a device launches the app, it can choose to become either the server or a client.

The server is listening to UDP messages to detect clients in the network and opens a TCP socket to receive connection's requests.
Clients instead, will broadcast UDP messages for discovery purposes.
Once the server receives a discovery message, it broadcasts a discovery response message and then the client then connects to the server via TCP.


## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

**[MIT license](http://opensource.org/licenses/mit-license.php)**
- Copyright 2020 © Annino De Petra
