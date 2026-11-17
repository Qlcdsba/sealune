///|
test "attach a conflicting handoff to both items and keep receipt-only rows" {
  let release : @ledger.Slip = {
    handoff: "A",
    item: "P",
    sender: "field",
    receiver: "store",
    seal: "S",
    time: 0L,
  }
  let receipt = { ..release, item: "Q", }
  let result = @ledger.review([release], [receipt, { ..receipt, handoff: "B", }])
  assert_eq(result.items.length(), 2)
  assert_true(result.items[0].issues is [@ledger.PairIssue(0)])
  assert_true(
    result.items[1].issues is [@ledger.PairIssue(0), @ledger.PairIssue(1)],
  )
  assert_true(
    result.items[1].sources is [@ledger.ReceiptRow(1), @ledger.ReceiptRow(2)],
  )
}
