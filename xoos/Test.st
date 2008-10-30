{ import: Objects }

Test : Object ( dict )

Test add: class
[
  dict = nil ifTrue: [ dict := Dictionary new ].
  dict at: class debugName put: class
]

Test run
[
  'Starting system self-test..' putln.
  dict = nil ifTrue: [ dict := Dictionary new ].
  dict valuesDo: [ :case | ('Testing ' , case debugName , ':') putln. case perform: #selftest ].
  'System self-test complete.' putln.
]

