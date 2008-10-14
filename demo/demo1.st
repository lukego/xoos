"# Introduction"

"This is my first program written in the Pepsi programming language.
Pepsi is a Smalltalk-like language implemented on the Cola runtime
system. Pepsi isn't documented so I've been learning it by example and
by questioning people who know about it. I hope that by reading this
program you'll learn the gist of what I know about Pepsi so far.

This program is in fact a stand-alone OLPC XO operating system that
does one thing: paint the screen blue."

"# Preamble"

"First we import the library of basic objects. This provides us with
access to all of the objects defined in the `function/objects/'
directory."

{ import: Object }

"and to keep our inline C code from spilling over 80 columns we suck
in typedefs for `uchar'/`ushort'/`ulong'. I didn't see how to inline
C typedefs directly in this file so I created this `types.h'"

{ include "types.h" }

"# CPU"

CPU : Object ()

"The CPU object knows how to read and write memory. To poke a value
into memory we first convert it from a Cola encoded object reference
(called an `oop' -- essentially a tagged pointer) into a raw machine integer by
sending the `_integerValue' message. Then we can poke it straight into
memory with inline C. Here are the variants for 8/16/32-bit values:"

CPU at: addr poke8:  value [ self _at_: addr _int poke8_:  value _int ]
CPU at: addr poke16: value [ self _at_: addr _int poke16_: value _int ]
CPU at: addr poke32: value [ self _at_: addr _int poke32_: value _int ]

Object _int
[ "Answer the receiver's value as a machine integer. (A short name.)"
  ^self _integerValue ]

CPU _at_: _addr poke8_:  _val { *((volatile uchar*) v__addr) = (uchar) (int)v__val; }
CPU _at_: _addr poke16_: _val { *((volatile ushort*)v__addr) = (ushort)(int)v__val; }
CPU _at_: _addr poke32_: _val { *((volatile ulong*) v__addr) = (ulong) (int)v__val; }

"That's pretty funky looking code but it's quite atypical: we are
adding new primitives to the runtime system here after all. To
decipher that you're going to have to know what languages you're
looking at and what the funny naming conventions are all about.

The code between square brackets `[ ... ]' is Pepsi and the code
between curly braces `{ ... }' is C. You can mix statements in these
two languages freely -- you can throw some C code between curly braces
into your Pepsi code whenever you feel like it. Pepsi-level variables
are available in C with the `v_' name prefix.

The unsightly underscores are a convention for type information:
variables assigned to Cola objects have simple names, and variables
assigned to raw machine values are prefixed with underscores. You can
store any value you like in these variables (they're accessible from
C) but you have to make sure to only use proper objects as the
receivers of messages.

Got it?

Let's move on to reading from memory with peek:"

CPU peek8:  addr [ ^Integer unsignedValue: (self _peek8_:  addr _int) ]
CPU peek16: addr [ ^Integer unsignedValue: (self _peek16_: addr _int) ]
CPU peek32: addr [ ^Integer unsignedValue: (self _peek32_: addr _int) ]

CPU _peek8_:  _addr { return (oop)(int)(*(volatile uchar *)v__addr); }
CPU _peek16_: _addr { return (oop)(int)(*(volatile ushort*)v__addr); }
CPU _peek32_: _addr { return (oop)(int)(*(volatile ulong *)v__addr); }

"No worries!

Now I'm sure you can't wait any longer to know the encoding
scheme for `oop' values: 0 represents `nil', the odd number `n'
represents the SmallInteger `n >> 1', and even numbers are pointers to
object records. Simple huh? (We'll learn about the format of object
records another time.)

One last detail: we're sending `_integerValue' to convert Cola
integers into machine integers, but at the time of writing this isn't
understood by `SmallInteger'. Because we know the encoding rules we
can simply add a method to `SmallInteger' telling it to become a
machine integer by shifting its oop one bit to the right:"

SmallInteger _integerValue { _return (oop)(((long)v_self) >> 1); }

"So now we have peek and poke at our disposal."

"# Screen"

"The first thing we'll peek and poke is the framebuffer holding the
screen's pixel data. The Geode's framebuffer lives in main memory so
our peek and poke will work fine. We'll assume that Openfirmware has:
placed the framebuffer at `FD000000', set 1200x900 screen resolution,
and chosen the RGB 565 16-bit pixel format."

Screen : Object ( w h fb )
Screen initialize [ w := 1200. h := 900. fb := 0xFD000000 ]

Screen x: x y: y color: color [ CPU at: (fb + (2 * (x + (y * w)))) poke16: color ]
Screen x: x y: y              [ ^CPU peek16: (fb + (2 * (x + (y * w)))) ]

Screen fill: color
[
  self do: [:x :y | CPU at: 0xFCFFFFF0 poke32: x; at: 0xFCFFFFF4 poke32: y. self x: x y: y color: color ]
]

Screen do: aBlock
[
  0 to: (h - 1) do: [ :y | 0 to: (w - 1) do: [ :x | aBlock value: x value: y ] ]
]

[ Screen initialize ]

"## Color565"

"A few constant 565 colour values.."

Color565 : Object ()

Color565 red   [ ^0xF800 ]
Color565 green [ ^0x07E0 ]
Color565 blue  [ ^0x001F ]

"# Main"

"So what should our operating system actually do? How about printing a
message and painting the screen blue:"

[
  'Painting the screen blue..' putln.
  Screen fill: Color565 blue.
]

