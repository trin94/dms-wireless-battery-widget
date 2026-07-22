# The pill stays two views, one per orientation

The horizontal and vertical pill views are near-identical, and an architecture review ranked
merging them into one axis-parameterized module as the strongest refactor candidate. We tried
the merge and rejected it: the part that differs is the structural spine, and QML cannot make
the axis a parameter while preserving rendering. A Grid-based module loses whole-pixel
centring — anchor centring rounds to whole pixels (`alignWhenCentered`), Grid's item alignment
does not — so icons and text shift by up to half a pixel; an offscreen probe comparing leaf
geometry against the old views confirmed the drift. Keeping real Row/Column containers and
moving shared children into the active one via `parent:` bindings fails differently: binding
evaluation order is unspecified, so children arrive in the positioner in arbitrary order (a
separator rendered after its entry's icon), and the fix — imperative reparenting on
Component.onCompleted — was judged worse than the duplication. Extracting the shared leaves
(separator, bolt slot, percent text) into components was also considered and skipped: it still
leaves the skeletons duplicated while making each file harder to read as one positioner tree.
Decision: both views stay, and every entry restyle lands twice, kept in sync by hand.
Consequence: the two files can drift apart again; a change to one pill view should always be
checked against its sibling.
