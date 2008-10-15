"# Introduction"

{ import: Object }

"Today we'll experiment with calling back into Openfirmware from
Pepsi. We're going to do something simple: print a list of all the
hardware devices known to the firmware.

Openfirmware provides its 'clients' (operating systems) with a C
function pointer for calling back into the firmware for help. The
function takes one argument -- a pointer to this structure:"

  "--------------------------------------+
  | Name of the client interface service |
  +--------------------------------------+
  | Number of input arguments            |
  +--------------------------------------+	
  | Number of return values              |
  +--------------------------------------+	
  | Input arguments (arg1, ..., argN)    |
  +--------------------------------------+	
  | Returned values (ret1, ..., retN)    |
  +--------------------------------------"

"The named client services include `interpret' to execute Forth code,
`open' to open a device (file, socket, etc), `claim' to allocate
memory, etc. The IEEE 1275 standard for Openfirmware specifies a bunch
of services and you can download it from the Openfirmware Wikipedia
page. You can also query the exact set of services available on the
OLPC XO by examining the `client-services' Forth vocabulary:

`dev /client-services words'

The primary sources of information I've used are the Openfirmware
source code (`clients/' directory) and the IEEE standard. We've also
bought a copy of Firmworks' Client Interface manual from Mitch
Bradley's company Firmworks. Mitch is one of the nicest and most
helpful guys you'll find on the internet so we're happy to pay a few
dollars for the manual! But you can read the IEEE standard instead."

"# OFW"

"The OFW object provides a direct interface to Openfirmware. Each of
its methods invokes one Firmware service and takes simple integer or
string arguments. Later we're going to build an object-oriented layer over
the top."

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

"Here're a few convenient wrappers for calls that return one value:"

OFW call1: word inputs: inputs [ ^(OFW call: word inputs: inputs nresults: 1) at: 0 ]
OFW call1: word input: input   [ ^OFW call1: word inputs: (Array with: input) ]
OFW call1: word                [ ^OFW call1: word inputs: (Array new: 0) ]

"Openfirmware organises the hardware in the machine into a 'device
tree'. The tree has a root (the CPU) with subtrees of children (the
PCI bus, USB bus, etc). We get the root by asking for the `peer' of 0
and then we can traverse the tree with successive calls to `peer'
and `child'."

OFW peer:   phandle  [ ^Integer value_: (OFW call1: 'peer' input: phandle) ]
OFW child:  phandle  [ ^Integer value_: (OFW call1: 'child' input: phandle) ]
OFW parent: phandle  [ ^Integer value_: (OFW call1: 'phandle' input: phandle) ]

"The `package-to-path' service returns the printable name of a node in
the device tree. Here we allocate a Pepsi string and pass its internal
buffer into the firmware as a C-string. (T'would seem that Ian has
taken pains to make Pepsi strings convenient to pass into C by making
their internal representation be a C string.)"

OFW packageToPath: phandle
[
  | str |
  str := String new: 256.
  OFW call1: 'package-to-path' inputs: (Array with: phandle with: str with: str size).
  ^str
]

"And while we're at it here's a binding to the `milliseconds' service
to find out how many millis have elapsed since we booted:"

OFW milliseconds [ ^Integer value_: (OFW call1: 'milliseconds') ]

"# DeviceNode"

"Here's an object-oriented interface to the device tree:"

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

"Yoshiki tells me that this is the Smalltalk idiom for what I want:"

Object          ifNotNilDo: aBlock [ aBlock value: self ]
UndefinedObject ifNotNilDo: aBlock [ ^nil ]

"# Dumping the device tree"

"Now we're ready to dump the device tree and make a couple of gratuitous calls to `milliseconds':"

[
  | start end |
  start := OFW milliseconds.
  DeviceNode root dump.
  end := OFW milliseconds.
  'dumped in ' put. (end - start) print. 'ms' putln.
]

