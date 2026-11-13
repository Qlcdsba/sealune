///|
fn chain_slip(
  handoff : String,
  item : String,
  sender : String,
  receiver : String,
  time : Int64,
) -> @ledger.Slip {
  { handoff, item, sender, receiver, time, seal: "S-1", }
}

///|
test "sort separately by item and report both independent chain faults" {
  let first = chain_slip("T-1", "P-1", "field", "store", 10L)
  let second = chain_slip("T-2", "P-1", "office", "lab", 15L)
  let other = chain_slip("T-3", "P-2", "field", "lab", 12L)
  let first_receipt = { ..first, time: 20L, }
  let result = @ledger.reconcile([second, other, first], [
    first_receipt, other, second,
  ])
  let findings = @ledger.check_continuity(result)
  let expected : Array[@ledger.ChainFault] = [
    OverlappingCustody,
    CustodianMismatch,
  ]
  assert_eq(findings.map(finding => finding.fault), expected)
  debug_inspect(
    findings.map(finding => {
      (finding.first.release_row, finding.second.release_row)
    }),
    content="[(3, 1), (3, 1)]",
  )
}

///|
test "do not infer custody gaps at the boundaries of tied handoffs" {
  let a = chain_slip("T-1", "P-1", "field", "store", 10L)
  let b = chain_slip("T-2", "P-1", "other", "lab", 20L)
  let c = chain_slip("T-3", "P-1", "other", "office", 20L)
  let d = chain_slip("T-4", "P-1", "other", "field", 30L)
  let result = @ledger.reconcile([a, b, c, d], [d, c, b, a])
  let findings = @ledger.check_continuity(result)
  let expected : Array[@ledger.ChainFault] = [AmbiguousOrder]
  assert_eq(findings.map(finding => finding.fault), expected)
}

///|
test "a release at the prior receipt time can continue the chain" {
  let a = chain_slip("T-1", "P-1", "field", "store", 10L)
  let b = chain_slip("T-2", "P-1", "store", "lab", 20L)
  let result = @ledger.reconcile([a, b], [{ ..a, time: 20L, }, b])
  debug_inspect(@ledger.check_continuity(result).length(), content="0")
}

///|
test "a short handoff cannot hide a still-open earlier transfer" {
  let a = chain_slip("T-1", "P-1", "field", "store", 10L)
  let b = chain_slip("T-2", "P-1", "store", "lab", 20L)
  let c = chain_slip("T-3", "P-1", "lab", "archive", 30L)
  let result = @ledger.reconcile([a, b, c], [{ ..a, time: 40L, }, b, c])
  let findings = @ledger.check_continuity(result)
  let expected : Array[@ledger.ChainFault] = [
    OverlappingCustody,
    OverlappingCustody,
  ]
  assert_eq(findings.map(finding => finding.fault), expected)
  debug_inspect(
    findings.map(finding => finding.first.release.handoff),
    content="[\"T-1\", \"T-1\"]",
  )
}
