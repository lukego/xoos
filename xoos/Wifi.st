"Copyright 2008 Luke Gorrie <luke@member.fsf.org>
 See the included file LICENSE for license terms. (BSD.)"

{ import: Objects }
{ import: OFW }

"# Wifi"

Wifi : Object ( wifi buffer )

Wifi init
[
  wifi := Device open: '/wlan'.
  buffer := String new: 1600.
]

Wifi essid: essid [ ^OFW interpret: 'essid ' , essid inputs: #() ]
Wifi associate    [ ^OFW callMethod: 'do-associate' device: wifi inputs: #() ]
Wifi read         [ ^OFW read: wifi on: buffer ]
Wifi write: frame [ ^OFW write: wifi data: frame ]

Wifi blockingRead
[ | frame |
  [ frame := self read. frame isCollection ] whileFalse.
  ^frame
]

Wifi arp
[
  "who has 192.168.128.1? tell 192.168.128.44"
  ^#[255 255 255 255 255 255 0 8 116 228 110 188 8 6 0 1 8 0 6 4 0 1 0 8 116 228 110 188 192 168 128 44 0 0 0 0 0 0 192 168 128 1]
]

Wifi selftest
[
   | x |
   'testing wifi.' putln.
   Wifi init.
   'writing wifi: ' putln.
   (Wifi write: Wifi arp) println.
   'reading wifi: ' putln.
   Wifi blockingRead println.
]

[ Test add: Wifi ]
