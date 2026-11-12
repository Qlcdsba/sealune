///|
fn pair_code(fault : @ledger.PairFault) -> String {
  match fault {
    MissingRelease => "missing_release"
    MissingReceipt => "missing_receipt"
    DuplicateRelease => "duplicate_release"
    DuplicateReceipt => "duplicate_receipt"
    ItemMismatch => "item_mismatch"
    SenderMismatch => "sender_mismatch"
    ReceiverMismatch => "receiver_mismatch"
    SealMismatch => "seal_mismatch"
    ReceiptBeforeRelease => "receipt_before_release"
  }
}

///|
fn chain_code(fault : @ledger.ChainFault) -> String {
  match fault {
    AmbiguousOrder => "ambiguous_order"
    OverlappingCustody => "overlapping_custody"
    CustodianMismatch => "custodian_mismatch"
  }
}

///|
fn match_reference(pair : @ledger.Match) -> Json {
  {
    "handoff": pair.release.handoff,
    "release_row": pair.release_row,
    "receipt_row": pair.receipt_row,
  }
}

///|
fn pair_finding(finding : @ledger.Finding) -> Json {
  {
    "code": pair_code(finding.fault),
    "handoff": finding.handoff,
    "release_rows": finding.releases,
    "receipt_rows": finding.receipts,
  }
}

///|
fn chain_finding(finding : @ledger.ChainFinding) -> Json {
  {
    "code": chain_code(finding.fault),
    "item": finding.item,
    "first": match_reference(finding.first),
    "second": match_reference(finding.second),
  }
}

///|
fn make_report(
  result : @ledger.Reconciliation,
  gaps : Array[@ledger.ChainFinding],
) -> Json {
  {
    "matches": result.matches.map(match_reference),
    "pair_findings": result.findings.map(pair_finding),
    "continuity_findings": gaps.map(chain_finding),
  }
}
