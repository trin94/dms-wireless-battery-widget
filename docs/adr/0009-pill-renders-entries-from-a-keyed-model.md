# The pill renders entries from a keyed model

The pill's Repeater used to model the entry count, not the entries list: the view model
rebuilds entries as a fresh array on every reading change, and modelling that array directly
would recreate all delegates each time, cutting the bolt slot animation short. The count-model
kept delegates alive while the count stayed constant, but any tracked device joining or leaving
changed the count and recreated every delegate, so per-entry animation was impossible and
running animations on unrelated entries were reset. Decision: each pill view feeds its Repeater
from `WirelessBatteryEntryModel`, a keyed ListModel in the logic layer that syncs against the
view model's entries in place — rows are removed, inserted, moved, or updated by device key, so
a join or leave touches only that entry's row, a reading change updates roles without any
structural change, and the delegates of surviving entries are never recreated. The diff-sync is
a pure logic component with its own tests; per ADR 0007 the model wiring appears in both pill
views. Rendering is unchanged — the delegates read the same values through roles instead of
indexing into the entries array. The placeholder rides the same model under the reserved key
`placeholder`, so keys identify rows, not devices, and the join and leave choreography applies
to the placeholder unchanged.
