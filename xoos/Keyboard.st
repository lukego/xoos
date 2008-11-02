{ import: Objects }
{ import: OFW }

"# Keyboard"

Keyboard : Object ( keyboard )

Keyboard init [ keyboard := Device open: '/keyboard' ]
Keyboard poll [ ^KeyboardEvent poll: keyboard ]


KeyboardEvent : Object ( scancode key state )

KeyboardEvent scancode [^scancode]
KeyboardEvent key [^key]
KeyboardEvent state [^state]

KeyboardEvent poll: keyboard
[
  "We use these keyboard device methods:
   get-scancode   ( time -- 0 | scancode -1 )
   scancode->char ( scancode -- 0 | ascii -1 )"
  | res |
  res := keyboard call: 'get-scancode' input: 0.
  res second == 0 ifTrue: [ ^nil ].

  self := self new.
  scancode := res third.
  state := (scancode bitAnd: 0x80) == 0 ifTrue: [#down] ifFalse: [#up].
  scancode := scancode bitAnd: 0x80 bitInvert32.
  res := keyboard call: 'get-ascii' input: scancode.
  res second == 0 ifFalse: [ key := res third ].
  ^self
]

KeyboardEvent printOn: aStream
[
  aStream nextPutAll: 'KeyboardEvent{'; print: scancode; nextPut: $ .
  key == nil ifFalse: [ aStream nextPut: key; nextPut: $  ].
  aStream print: state; nextPut: $}.
]

"# Test"

Keyboard selftest
[
  Keyboard init.
  'printing keyboard events until you press ESC:' putln.
  [true] whileTrue: [
    Keyboard poll ifNotNilDo: [ :evt |
      evt println.
      evt scancode == 1 ifTrue: [^self].
      OFW waitms: 10 ]
  ].
]

[ Test add: Keyboard ]

