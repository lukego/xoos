{ import: Objects }
{ import: Test }
{ import: OFW }

{ include "types.h" }

"# CPU"

CPU : Object ()

CPU   at:  addr poke:  value [ self _at_: addr _int poke_: value _int ]
CPU _at_: _addr poke_: _val  { *((volatile ulong*) v__addr) = (ulong) (int)v__val; }

CPU  peek:   addr [ ^Integer unsignedValue_: (self _peek_: addr _int) ]
CPU _peek_: _addr { _return (oop)(int)(*(volatile ulong *)v__addr); }

CPU at: addr poke: value bits: bits position: position
[
  | mask template new |
  mask := ((1 << bits) - 1) << position.
  template := (CPU peek: addr) bitAnd: mask bitInvert32.
  new := template bitOr: (value << position bitAnd: mask).
  CPU at: addr poke: new
]

Object _int [ ^self _integerValue ]

"# GP"

GP : Object ()

GP at: addr poke: value [ CPU at: addr + 0xFE000000 poke: value ]
GP peek: addr           [ ^CPU peek: addr + 0xFE000000 ]

GP dstX: x dstY: y       [ self at: 0x0 poke: x @ y ]
GP srcX: x srcY: y       [ self at: 0x4 poke: x @ y ]
GP strideSrc: s dst: d   [ self at: 0x8 poke: (s joinedWith: d) ]
GP width: w height: h    [ self at: 0xC poke: (w joinedWith: h) ]
GP waitReady             [ [ ((self peek: 0x44) bitAnd: 4) = 0 ] whileFalse ]
GP waitDone              [ [ ((self peek: 0x44) bitAnd: 1) = 0 ] whileFalse ]
GP rasterOpMode: ropMode [ self at: 0x38 poke: ropMode ]
GP blitMode: blitMode    [ self at: 0x40 poke: blitMode ]
GP pattern: color        [ self at: 0x18 poke: color ]

Integer @ y
[ "Convert x@y to linear address."
  ^(self + (y * DP width)) * (DP bpp / 8)
]

Integer joinedWith: n [ ^(self halfword << 16) bitOr: n halfword ]
Integer halfword      [ ^self bitAnd: 0xFFFF ]

GP fill [ self blitWithRopMode: 0x800000F0 blitMode: 0 ]
GP move [ self blitWithRopMode: 0x600000CC blitMode: 1 ]

GP blitWithRopMode: rop blitMode: blit [ self waitReady; rasterOpMode: rop; blitMode: blit; waitDone ]

"# Framebuffer"

Framebuffer : Object ()

Framebuffer address [ ^0xfd000000 ]
Framebuffer bytes   [ ^16 * 1024 * 1024 ]
Framebuffer lines   [ ^self bytes // DP bytesPerPixel // DP width ]

Framebuffer backup
[ "Copy the visible region of the framebuffer to the end of the framebuffer."
  GP srcX: 0 srcY: 0;
     dstX: 0 dstY: (Framebuffer lines - DP height);
     width: DP width height: DP height;
     move
]

Framebuffer restore
[ "Copy the invisible region at the end of the framebuffer over the visible region."
  GP srcX: 0 srcY: (Framebuffer lines - DP height);
     dstX: 0 dstY: 0;
     width: DP width height: DP height;
     move
]

Framebuffer selftest
[
  'backup and restore screen memory:' putln.
  Framebuffer backup.
  'This text will disappear in 1 second.' putln.
  OFW waitms: 1000.
  Framebuffer restore.
  StdOut cr.
  OFW waitms: 1000.
]

[ Test add: Framebuffer ]

"# DP"

DP : Object ()

DP width       [ ^1200 ]
DP height      [ ^900 ]

DP bpp         [ ^8 + (self dispMode * 8) ]
DP bpp: bpp
[
  self dispMode: (bpp // 8 - 1).
  self frameBufferLineSize: bpp.
  GP strideSrc: (DP width * bpp // 8) dst: (DP width * bpp // 8).
]

DP frameBufferLineSize: bpp
[
  CPU at: 0xFE004030 poke: (DP width * (bpp // 8) // 8) bits: 10 position: 0.
  CPU at: 0xFE004034 poke: (DP width * (bpp // 8) // 8) bits: 16 position: 0.
]

DP bytesPerPixel [ ^self bpp / 8 ]

DP dispMode    [ ^((CPU peek: 0xFE004008) bitAnd: 0x00000300) >> 8 ]
DP dispMode: n [ CPU at: 0xFE004008 poke: n bits: 2 position: 8 ]

[ Test add: DP ]

DP selftest2
[
  Framebuffer backup.
  [
  DP bpp: 32.
  self drawBlocks.
  OFW waitms: 5000.
  DP bpp: 16.
  Framebuffer restore.
  42
  ]  whileTrue.
]

DP selftest
[
  'DP bit depths:' putln.
  Framebuffer backup.
  OFW waitms: 1000.
  #(8 16 24 32) do:
    [ :bpp |
      DP bpp: 16.
      Framebuffer restore.
      DP bpp: bpp.
      OFW waitms: 1000.
      self drawBlocks.
      OFW waitms: 1000.
      DP bpp = bpp ifTrue: [ bpp print. '-ok ' put ] ifFalse: [ bpp print. '-error' put. ] ].
  DP bpp: 16.
  Framebuffer restore.
  'restored framebuffer' putln.
]

DP drawBlocks [
  | colors w h |
  w := DP width // 10.
  h := DP height // 10.
  colors := #( 0x000000 0xFF0000 0x00FF00 0x0000FF ).
  GP width: w height: h.
  0 to: 9 do: [ :y | 0 to: 9 do: [:x |
    OFW waitms: 100.
    GP pattern: (colors at: x + y \\ colors size);
       dstX: x*w dstY: y*h;
       fill.
  ]]
]

"# Test"

Geode : Object ()
[ Test add: Geode ]

Geode selftest
[
]
