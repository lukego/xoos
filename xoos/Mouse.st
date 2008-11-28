"Copyright 2008 Luke Gorrie <luke@member.fsf.org>
 See the included file LICENSE for license terms. (BSD.)"

{ import: Objects }
{ import: OFW }

"# Mouse"

Mouse : Object ( mouse )

Mouse init
[
  mouse := Device open: '/mouse'.
  mouse call: 'stream-mode'.
]

Mouse poll
[
  ^MouseEvent from: (mouse call: 'stream-poll?').
]

MouseEvent ( dx dy left right )

MouseEvent dx    [^dx]
MouseEvent dy    [^dy]
MouseEvent left  [^left]
MouseEvent right [^right]

MouseEvent from: poll "( catch-res event? buttons dy dx )"
[
  poll second = 0 ifTrue: [ ^nil ].

  self := self new.
  dx := poll at: 4.
  dy := poll at: 3.
  left := ((poll at: 2) bitAnd: 1) ~~ 0.
  right := ((poll at: 2) bitAnd: 4) ~~ 0.
  ^self
]

MouseEvent printOn: aStream
[
  aStream nextPutAll: 'MouseEvent{'; print: dx; nextPut: $ ; print: dy.
  left  ifTrue: [aStream nextPutAll: ' left'].
  right ifTrue: [aStream nextPutAll: ' right'].
  ^aStream nextPut: $}.
]

"# Test"

Mouse selftest
[
  Mouse init.
  'printing mouse events until you press the right button.' putln.
  [true] whileTrue: [
    Mouse poll ifNotNilDo: [:evt |
      evt println.
      evt right ifTrue: [^self].
      OFW waitms: 10 ]
  ].
]

[ Test add: Mouse ]

