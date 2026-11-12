///|
fn slip(
  handoff : String,
  seal~ : String = "S-1",
  time~ : Int64 = 100L,
) -> @ledger.Slip {
  { handoff, item: "P-1", sender: "field", receiver: "store", seal, time, }
}

///|
test "pair by handoff ID while retaining each ledger's row numbers" {
  let result = @ledger.reconcile([slip("T-1"), slip("T-2")], [
    slip("T-2"),
    slip("T-1", time=101L),
  ])
  debug_inspect(result.findings.length(), content="0")
  debug_inspect(
    result.matches.map(pair => (pair.release_row, pair.receipt_row)),
    content="[(1, 2), (2, 1)]",
  )
}

///|
test "keep all source rows when a receipt is ambiguous" {
  let result = @ledger.reconcile([slip("T-1"), slip("T-2")], [
    slip("T-1"),
    slip("T-3"),
    slip("T-1"),
  ])
  debug_inspect(result.matches.length(), content="0")
  let expected : Array[@ledger.Finding] = [
    {
      handoff: "T-1",
      fault: DuplicateReceipt,
      releases: [1],
      receipts: [1, 3],
    },
    { handoff: "T-2", fault: MissingReceipt, releases: [2], receipts: [], },
    { handoff: "T-3", fault: MissingRelease, releases: [], receipts: [2], },
  ]
  assert_eq(result.findings, expected)
}

///|
test "show seal and time discrepancies on the same handoff" {
  let result = @ledger.reconcile([slip("T-1")], [
    slip("T-1", seal="S-8", time=99L),
  ])
  let expected : Array[@ledger.PairFault] = [SealMismatch, ReceiptBeforeRelease]
  assert_eq(result.findings.map(finding => finding.fault), expected)
  debug_inspect(result.matches.length(), content="0")
}
