# Reconciling slips from a MoonBit application

Decode each desk's export independently. The reconciliation keeps the row
numbers in the two input arrays so a caller can highlight the original entries.

```mbt check
///|
test "highlight a seal discrepancy in both ledgers" {
  let released =
    #|[{"handoff":"T-01","item":"P-14","sender":"field","receiver":"store","seal":"S-017","time":10}]
  let received =
    #|[{"handoff":"T-01","item":"P-14","sender":"field","receiver":"store","seal":"S-071","time":12}]
  let result = @ledger.reconcile(
    @ledger.decode_ledger(released[:]),
    @ledger.decode_ledger(received[:]),
  )
  let finding = result.findings[0]
  assert_true(finding.fault is SealMismatch)
  assert_eq(finding.releases, [1])
  assert_eq(finding.receipts, [1])
}
```
