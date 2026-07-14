# Home v15 — amount typography audit

## Scope

- Surface: Home hero, personal light state
- Question: whether `.faithful-amount-row` feels too stylistically distinctive
- Evidence: `01-home-current.jpg`

## Step 1 — Read the monthly total

Health: needs minor refinement.

- The total is immediately discoverable and clearly owns the highest level in the card.
- The amount resolves to the Mincho display stack at 33px/700 with `-1.32px` tracking.
- The month title and Joy metrics use the sans body stack. This makes the amount the only strongly
  editorial element in the primary dashboard hierarchy.
- The contrast is attractive in isolation, but the sharp Mincho terminals plus tight tracking make
  the value feel closer to a receipt or magazine headline than to the rest of the calm utility UI.
- The narrow strokes can lose clarity sooner than the sans numerals at small scale or lower display
  quality. Screenshot evidence alone cannot verify Dynamic Type, zoom, or screen-reader behavior.

## Recommendation

Keep the large 33px hierarchy, tabular numerals, and dark-green color, but move this value to the
body/sans family with a 700–800 weight and slightly relaxed negative tracking around `-0.02em`.
This preserves emphasis while bringing the amount back into the same system as the month title,
ledger values, and Joy metrics.
