# Sealune

Match handoff records. Find custody gaps.

Sealune reconciles two independently kept records of physical custody: the release ledger and the receipt ledger. Each handoff carries an ID, item ID, sender, receiver, seal ID, and timestamp. The library flags discrepancies and returns the source rows for follow-up.

Once two slips agree, Sealune can compare consecutive handoffs for that item. It flags a different custodian, an outgoing handoff recorded before the previous receipt, and tied release times whose order needs human review. Unmatched slips are reported separately. A gap between confirmed handoffs can point to a missing record.

Run the library tests with `moon test --deny-warn`.
