# Sealune

Match handoff records. Find custody gaps.

Sealune reconciles two independently kept records of physical custody: the release ledger and the receipt ledger. Each handoff carries an ID, item ID, sender, receiver, seal ID, and timestamp. The library flags discrepancies and returns the source rows for follow-up.

This first milestone covers matching one handoff. Run its library tests with `moon test`.
