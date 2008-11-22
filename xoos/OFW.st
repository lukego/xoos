"OFW.st -- Openfirmware client interface binding.
 Copyright 2008 Luke Gorrie <lukego@gmail.com>"

{ import: Objects }
{ import: Test }

OFW : Object ()

OFW call: word inputs: inputs
[ "Invoke an Openfirmware service and return the array of results."
  | array |
  array := self createCallRecord: word inputs: inputs numResults: 20.
  self callOFW_: array _elements.
  ^array from: (array size - 20) collect: [:v | Integer value_: v].
]

OFW createCallRecord: word inputs: inputs numResults: nresults
[ "Answer an array appropriate for passing to Openfirmware."
  | items |
  items := OrderedCollection new
            add:    word;
            add:    inputs size;
            add:    nresults;
            addAll: inputs;
            addAll: (Array new: nresults).
  ^(items collect: [ :e | e _value ]) asArray.
]

"The `call_firmware' C function is our entry point:"

OFW callOFW_: _array
{
    extern int call_firmware(void *);
    if (call_firmware(v__array) == 0)
        return v_self;
    else
        return 0;
}

"For convenience I've used an `_value' message to convert objects into
C types, without the caller bothering whether they're numbers or strings."

String          _value [ ^self _stringValue ]
Integer         _value [ ^self _integerValue ]
UndefinedObject _value [ ^0 _integerValue ]
ByteArray       _value [ ^self _bytes ]

OFW call1: word inputs: inputs [ ^(OFW call: word inputs: inputs) first ]
OFW call1: word input: input   [ ^OFW call1: word inputs: (Array with: input) ]
OFW call1: word                [ ^OFW call1: word inputs: #() ]

OFW peer:   phandle  [ ^OFW call1: 'peer' input: phandle ]
OFW child:  phandle  [ ^OFW call1: 'child' input: phandle ]
OFW parent: phandle  [ ^OFW call1: 'phandle' input: phandle ]

OFW packageToPath: phandle
[
  | str |
  str := String new: 256.
  OFW call1: 'package-to-path' inputs: (Array with: phandle with: str with: str size).
  ^str
]

OFW milliseconds [ ^OFW call1: 'milliseconds' ]

OFW waitms: millis
[
  OFW interpret: 'ms' inputs: (Array with: millis).
"
  | end |
  end := OFW milliseconds + millis.
  [ OFW milliseconds < end ] whileTrue.
"
]

OFW interpret: string inputs: inputs
[
  ^OFW call: 'interpret' inputs: (Array with: string), inputs
]

OFW open: device    [ ^OFW call1: 'open' input: device ]
OFW close: instance [ ^OFW call1: 'close' input: instance ]

OFW read: device into: buffer
[
  | res |
  res := (OFW call: 'read' inputs: (Array with: device with: buffer with: buffer size)) first.
  res > 0
    ifTrue:  [^buffer copyFrom: 0 to: res - 1]
    ifFalse: [^res].
]

OFW write: device data: data [ ^OFW write: device data: data size: data size ]

OFW write: device data: data size: size
[
  ^OFW call: 'write' inputs: (Array with: device with: data with: size)
]

OFW callMethod: name device: instance inputs: inputs
[
  ^OFW call: 'call-method' inputs: (Array with: name with: instance) , inputs.
]

"# DeviceNode"

DeviceNode : Object ( handle )

DeviceNode root  [ ^DeviceNode phandle: (OFW peer:  0)      ]
DeviceNode peer  [ ^DeviceNode phandle: (OFW peer:  handle) ]
DeviceNode child [ ^DeviceNode phandle: (OFW child: handle) ]
DeviceNode path  [ ^OFW packageToPath: handle ]

DeviceNode phandle: phandle
[
  (phandle = 0) ifTrue: [ ^nil ].
  self := self new.
  handle := phandle.
]

DeviceNode dump
[
  self do: [ :node | node path putln ]
]

DeviceNode do: aBlock
[
  aBlock value: self.
  self child ifNotNilDo: [ :node | node do: aBlock ].
  self peer  ifNotNilDo: [ :node | node do: aBlock ]
]

Object          ifNotNilDo: aBlock [ aBlock value: self ]
UndefinedObject ifNotNilDo: aBlock [ ^nil ]

"# Device"

Device : Object ( handle )
Device ihandle: ihandle
[
  (ihandle = 0) ifTrue: [^nil].
  self := self new.
  handle := ihandle.
]

Device open: name [ ^Device ihandle: (OFW open: name) ]

Device call: method inputs: inputs
[ ^OFW callMethod: method device: handle inputs: inputs ]

Device call: method input: input
[ ^OFW callMethod: method device: handle inputs: (Array with: input) ]

Device call: method
[ ^OFW callMethod: method device: handle inputs: #() ]

Device _value [ ^handle _value ]

"# Test cases"

OFW selftest
[
  | nodes |
  'traversing device tree: ' put.
  nodes := 0.
  DeviceNode root do: [ :node | nodes := nodes + 1 ].
  ((nodes asString) , ' nodes.') putln.
]

