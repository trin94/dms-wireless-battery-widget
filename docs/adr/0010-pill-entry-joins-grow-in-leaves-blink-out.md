# Pill entry joins grow in, leaves blink out

With the keyed entry model (ADR 0009) a join or leave touches only that entry's delegate, so
the pill can animate entry changes. Decision: a joining entry grows in at its sorted position —
the delegate scales its main-axis size by a reveal factor and squares that factor for opacity,
so the fade lands with the tail of the growth; neighbors slide apart through a positioner move
transition, and the capsule follows through a Behavior on the view root's implicit size. That
Behavior forces a wrapper Item around the positioner: a Behavior on a positioner's own implicit
size never fires, because the positioner writes it internally from C++ and bypasses property
interceptors. A leaving entry instead disappears immediately — no shrink animation, no
kept-alive "leaving" entries. The closing slide of the neighbors plus the capsule shrink masks
the blink-out, and the exit machinery (keeping a leaving entry's model row alive until an
animation finishes) was judged not worth its complexity. Initial population renders without
animation: delegates created while the view instantiates complete before the root arms the
reveal. There is no user-facing
setting; the pill uses the bar's standard motion (shortDuration, standardEasing) so entry
changes match the bolt slot. Per ADR 0007 the animation lands twice, once per pill view.
