{ import: Objects }
{ import: OFW }
{ import: Test }
{ import: File }

OFWFile : Object ( id )

OFWFile withDevice: devid
[
  devid == 0 ifTrue: [ ^nil ].
  self := self new.
  id := devid.
]

OFWFile open: path     [ ^self withDevice: (OFW open: path) ]
OFWFile create: path   [ ^self withDevice: (OFW create: path) ]
OFWFile close          [ OFW close: id ]
OFWFile nextPut: aByte [ self next: 1 putAll: (String with: aByte) ]

OFWFile next: size putAll: aString
[
  OFW write: id data: aString size: size
]

OFWFile read: aCollection at: offset size: size
[
  ^OFW read: id into: aCollection offset: offset size: size
]

OFWFile write: device data: data size: size
[
  self next: size putAll: data
]

[ File primFile: OFWFile ]

FilePatch : Object ()
FilePatch selftest
[
  | file |
  'opening file' putln.
  file := File open: 'u:\\boot\\olpc.fth'.
  'contents:' putln.
  (FileStream on: file) contents println.
]

[
  | stdin stdout |
  stdin  := Device ihandle: (OFW variable: 'stdin').
  stdout := Device ihandle: (OFW variable: 'stdout').
  StdIn := SharedFile withPrimFile: stdin name: '<stdin>'.
  StdOut := File withPrimFile: stdout name: '<stdout>'.
  StdErr := File withPrimFile: stdout name: '<stderr>'.
]

[ Test add: FilePatch ]
