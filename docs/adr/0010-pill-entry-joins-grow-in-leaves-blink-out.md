# Pill entry joins grow in, leaves blink out

With the keyed entry model (ADR 0009) a join or leave touches only that entry's delegate, so
the pill can animate entry changes. Decision: a joining entry grows in at its sorted position —
the delegate scales its main-axis size by a reveal factor and squares that factor for opacity,
so the fade lands with the tail of the growth; the growing entry pushes its neighbors apart and
the capsule follows the content directly, since the reveal already animates both frame by
frame. A leaving entry instead disappears immediately — no shrink animation, no kept-alive
"leaving" entries. The closing slide of the neighbors plus the capsule shrink masks the
blink-out, and the exit machinery (keeping a leaving entry's model row alive until an animation
finishes) was judged not worth its complexity. Closing slide and capsule shrink ease only the
snap of a leave: a positioner move transition and a Behavior on the view root's implicit size
arm when a model row is removed and disarm once the ease finishes. Both must stay out of every
other change — joins and the bolt slot animate the content themselves, and easing an
already-animated change makes the capsule and the neighbors trail the content: entries clipped
at the trailing edge, gaps that squeeze and wobble. The Behavior also forces a wrapper Item
around the positioner: a Behavior on a positioner's own implicit size never fires, because the
positioner writes it internally from C++ and bypasses property interceptors. Initial population renders without
animation: delegates created while the view instantiates complete before the root arms the
reveal. There is no user-facing
setting; the pill uses the bar's standard motion (shortDuration, standardEasing) so entry
changes match the bolt slot. Per ADR 0007 the animation lands twice, once per pill view.
