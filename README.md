<p align="center"> 
<img src="https://user-images.githubusercontent.com/6486741/76807958-1327d680-67de-11ea-93df-928ded8ba95d.png" width=125px>
</br><img src="https://img.shields.io/badge/iOS-swift-green">
</p>


# PlaneTalk

<p align="center">
<img src="https://user-images.githubusercontent.com/6486741/76912323-62880880-68ab-11ea-938f-15b7519726db.gif">

</p>


PlaneTalk is an iOS Swift App which lets you send messages to other devices connected to the same Wi-fi network.
It's suitable in places like airplanes where there is no internet connection.

The core functionalities are all built around some TCP and UDP's `syscall` and uses `kevent` as event notification system.
The UDP protocol is only being used for discovery's purposes whereas the TCP protocol is being used to connect and communicate with the server.

## How it works
When a device opens the app, it automatically sends an UDP Broadcast message to detect any other device in the network. 
After sending the message, the device may
1) either receive another broadcast message sent from the server containing its IP 
2) or it may not receive any message.

In the 2) scenario, the device 
- becomes the server of the communication system
- keeps the UDP Broadcast up in order to receive broadcast messages of any new  device joining the network
- opens a TCP socket to receive connection's requests
- establish connections with the clients

In the 1) scenario, the device then fetches the IP of the server and establish a connection with it.

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

**[MIT license](http://opensource.org/licenses/mit-license.php)**
- Copyright 2020 © Annino De Petra
