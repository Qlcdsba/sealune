///|
fn source_reference(source : @ledger.SourceRow) -> Json {
  match source {
    ReleaseRow(row) => { "ledger": "release", "row": row }
    ReceiptRow(row) => { "ledger": "receipt", "row": row }
  }
}

///|
fn timeline_entry(pair : @ledger.Match) -> Json {
  {
    "handoff": pair.release.handoff,
    "sender": pair.release.sender,
    "receiver": pair.receipt.receiver,
    "seal": pair.release.seal,
    "release_time": pair.release.time.to_string(),
    "receipt_time": pair.receipt.time.to_string(),
    "release_row": pair.release_row,
    "receipt_row": pair.receipt_row,
  }
}

///|
fn item_report(review : @ledger.Review, item : @ledger.ItemReview) -> Json {
  let issues : Array[Json] = item.issues.map(issue => {
    match issue {
      PairIssue(index) => pair_finding(review.reconciliation.findings[index])
      ContinuityIssue(index) => chain_finding(review.continuity[index])
    }
  })
  {
    "item": item.item,
    "sources": item.sources.map(source_reference),
    "timeline": item.matches.map(timeline_entry),
    "issues": issues,
  }
}

///|
fn review_summary(review : @ledger.Review) -> Json {
  let mut flagged_items = 0
  let mut receipt_only_items = 0
  for item in review.items {
    if !item.issues.is_empty() {
      flagged_items += 1
    }
    if !item.sources.any(source => source is ReleaseRow(_)) {
      receipt_only_items += 1
    }
  }
  {
    "items": review.items.length(),
    "flagged_items": flagged_items,
    "receipt_only_items": receipt_only_items,
    "matches": review.reconciliation.matches.length(),
    "pair_findings": review.reconciliation.findings.length(),
    "continuity_findings": review.continuity.length(),
  }
}

///|
fn make_queue_report(review : @ledger.Review) -> Json {
  let queue = []
  for item in review.items {
    if !item.issues.is_empty() {
      queue.push(item_report(review, item))
    }
  }
  { "summary": review_summary(review), "queue": queue }
}
