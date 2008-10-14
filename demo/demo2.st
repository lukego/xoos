"# Introduction"

"This is my second program written in the Pepsi programming language.
Like the previous one it's an XO operating system that paints the
screen blue -- but this time we use the AMD GeodeLX chip's graphics
accelerator to do the real work.

The Geode includes an x86 CPU, a Graphics Processor (GP) for fast
memory operations (fill, copy, xor, blend, etc) on pixel data, a
Display Processor (DP) that can export an area of memory for display
on an external screen, and then a bunch of other components that are
less relevant for us today.

Grab a copy of the 'AMD Geode LX Processors Data Book' from AMD's
website for reference. That explains all the capabilities of the chip
and how to drive it.

Also: Last time I said that the Pepsi was undocumented but that
turns out not to be true. Here's information!
`http://pimuarta.com/software/cola/pepsi.html'"

"# CPU (recap)"

"Let's quickly do another 32-bit peek/poke. I'm going to pull in any
lines of code that I need from the previous project without fussing
about code reuse in libraries."

{ import: Object }
{ include "types.h" }

CPU : Object ()

CPU   at:  addr poke:  value [ self _at_: addr _int poke_: value _int ]
CPU _at_: _addr poke_: _val  { *((volatile ulong*) v__addr) = (ulong) (int)v__val; }

CPU  peek:   addr [ ^Integer unsignedValue_: (self _peek_: addr _int) ]
CPU _peek_: _addr { _return (oop)(int)(*(volatile ulong *)v__addr); }

Object _int [ ^self _integerValue ]

"# Geode Graphics Processor"

"We're going to write a very simple driver for the GP's 'blit'
operation. The blit updates a rectangle in the frame buffer in some
specified way: fill with a solid, copy from a source, blend with a
source, etc. This driver will be low-level in the sense that we'll use
some magic numbers and not invent symbolic names for everything. The
code will resemble Openfirmware's driver -- that's the file
`dev/geode/display/gp.fth' from their svn repository.

The interface towards the GP is a set of configuration registers that
are memory mapped into the range `0xFE000000' to `0xFE000078'. These
addresses look like normal RAM -- we can peek and poke them -- but
they're implemented in hardware by sending messages to the GP.

Here's the driver:"

GP : Object ()

GP at: addr poke: value [ CPU at: addr + 0xFE000000 poke: value ]
GP peek: addr           [ ^CPU peek: addr + 0xFE000000 ]

GP dstX: x dstY: y       [ self at: 0x0 poke: x @ y ]
GP srcX: x srcY: y       [ self at: 0x4 poke: x @ y ]
GP width: w height: h    [ self at: 0xC poke: (w joinedWith: h) ]
GP waitReady             [ [ ((self peek: 0x44) bitAnd: 4) = 0 ] whileFalse ]
GP waitDone              [ [ ((self peek: 0x44) bitAnd: 1) = 0 ] whileFalse ]
GP rasterOpMode: ropMode [ self at: 0x38 poke: ropMode ]
GP blitMode: blitMode    [ self at: 0x40 poke: blitMode ]
GP pattern: color        [ self at: 0x18 poke: color ]

Integer @ y
[ "Convert x@y to linear address."
  ^(self + (y * Display width)) * (Display bpp / 8)
]

Integer joinedWith: n [ ^(self halfword << 16) bitOr: n halfword ]
Integer halfword      [ ^self bitAnd: 0xFFFF ]

"Not such a lot of code, right?

The source and destination registers each want an offset from the
start of the frame buffer, the width/height register is a pair of
16-bit values, and the rasterOpMode and blitMode registers take
reasonably complicated bit-records for values.

Here's how to use the driver to fill a solid rectange in the frame buffer:"

GP fill: color
[ self fill: color x: 0 y: 0 width: Display width height: Display height ]

GP fill: color x: x y: y width: width height: height
[ "Fill the whole screen with a solid color. "
  GP dstX: x dstY: y;
     width: width height: height;
     rasterOpMode: 0x800000F0;
     pattern: color;
     blitMode: 0; "do it!"
     waitDone
]

"# Display"

"The display object's methods mostly return constants."

Display : Object ()
Display width  [ ^1200 ]
Display height [ ^900 ]
Display bpp    [ ^32 ]

"But there's also this method to poke a magic number into the Display
Processor (DP) to switch to 32-bits-per-pixel mode. I'm only doing
this because it makes colour constants easy to write -- e.g. 0x0000FF
for blue. (Remember that Openfirmware had setup 16-bit 5:6:5 by default.)"

Display init
[ "Set 32bpp mode"
  CPU at: 0xFE004008 poke: ((CPU peek: 0xFE004008) bitOr: 0x00000300).
]

"# Main"

[
  Display init.
  GP fill: 0x0000FF. "blue"
  [ true ] whileTrue.
]

"There you have it, blue screen and a busy loop!"
