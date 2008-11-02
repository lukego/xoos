{ import: Objects }

Integer bitInvert32 [ ^ self bitXor: 0xffffffff ]

Object          ifNotNilDo: aBlock [ ^aBlock value: self ]
UndefinedObject ifNotNilDo: aBlock [ ^nil ]

