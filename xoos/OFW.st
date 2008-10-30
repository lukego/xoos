"OFW.st -- Openfirmware client interface binding.
 Copyright 2008 Luke Gorrie <lukego@gmail.com>"

{ import: Objects }
{ import: Test }

OFW : Object ()

OFW call: word inputs: inputs nresults: nresults
[ "Invoke an Openfirmware service and return the array of results."
  | array |
  array := self createCallRecord: word inputs: inputs nresults: nresults.
  self callOFW_: array _elements.
  ^array copyFrom: (array size - nresults)
]

OFW createCallRecord: word inputs: inputs nresults: nresults
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

OFW call1: word inputs: inputs [ ^(OFW call: word inputs: inputs nresults: 1) at: 0 ]
OFW call1: word input: input   [ ^OFW call1: word inputs: (Array with: input) ]
OFW call1: word                [ ^OFW call1: word inputs: (Array new: 0) ]

OFW peer:   phandle  [ ^Integer value_: (OFW call1: 'peer' input: phandle) ]
OFW child:  phandle  [ ^Integer value_: (OFW call1: 'child' input: phandle) ]
OFW parent: phandle  [ ^Integer value_: (OFW call1: 'phandle' input: phandle) ]

OFW packageToPath: phandle
[
  | str |
  str := String new: 256.
  OFW call1: 'package-to-path' inputs: (Array with: phandle with: str with: str size).
  ^str
]

OFW milliseconds [ ^Integer value_: (OFW call1: 'milliseconds') ]

OFW waitms: millis
[
  | end |
  end := OFW milliseconds + millis.
  [ OFW milliseconds < end ] whileTrue.
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

"# Test cases"

[ Test add: OFW. ]

OFW selftest
[
  | nodes |
  'traversing device tree: ' put.
  nodes := 0.
  DeviceNode root do: [ :node | nodes := nodes + 1 ].
  ((nodes asString) , ' nodes.') putln.
]


