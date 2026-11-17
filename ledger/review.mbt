///|
/// Index into the original release or receipt ledger, starting at one.
pub(all) enum SourceRow {
  ReleaseRow(Int32)
  ReceiptRow(Int32)
}

///|
/// A reference to a finding in the original reconciliation results.
/// Finding indices start at zero.
pub(all) enum ReviewIssue {
  PairIssue(Int32)
  ContinuityIssue(Int32)
}

///|
pub(all) struct ItemReview {
  item : String
  sources : Array[SourceRow]
  matches : Array[Match]
  issues : Array[ReviewIssue]
}

///|
fn review_for(
  groups : Map[String, ItemReview],
  ordered : Array[ItemReview],
  item : String,
) -> ItemReview {
  match groups.get(item) {
    Some(review) => review
    None => {
      let review = { item, sources: [], matches: [], issues: [], }
      groups[item] = review
      ordered.push(review)
      review
    }
  }
}

///|
fn assign_pair_issue(
  groups : Map[String, ItemReview],
  releases : Array[Slip],
  receipts : Array[Slip],
  finding : Finding,
  issue : Int32,
) -> Unit {
  let seen : Map[String, Bool] = Map([])
  for row in finding.releases {
    let item = releases[row - 1].item
    if !(seen.get(item) is Some(_)) {
      groups[item].issues.push(PairIssue(issue))
      seen[item] = true
    }
  }
  for row in finding.receipts {
    let item = receipts[row - 1].item
    if !(seen.get(item) is Some(_)) {
      groups[item].issues.push(PairIssue(issue))
      seen[item] = true
    }
  }
}

///|
pub(all) struct Review {
  reconciliation : Reconciliation
  continuity : Array[ChainFinding]
  items : Array[ItemReview]
}

///|
/// Build an item-oriented review from both source ledgers. A mismatch
/// involving two item IDs is attached to each item. Unmatched source
/// rows remain visible, and matches are ordered by release time.
pub fn review(releases : Array[Slip], receipts : Array[Slip]) -> Review {
  let reconciliation = reconcile(releases, receipts)
  let continuity = check_continuity(reconciliation)
  let groups : Map[String, ItemReview] = Map([])
  let items = []
  for index, slip in releases {
    review_for(groups, items, slip.item).sources.push(ReleaseRow(index + 1))
  }
  for index, slip in receipts {
    review_for(groups, items, slip.item).sources.push(ReceiptRow(index + 1))
  }
  for pair in reconciliation.matches {
    groups[pair.release.item].matches.push(pair)
  }
  for index, finding in reconciliation.findings {
    assign_pair_issue(groups, releases, receipts, finding, index)
  }
  for index, finding in continuity {
    groups[finding.item].issues.push(ContinuityIssue(index))
  }
  for item in items {
    item.matches.sort_by((first, second) => {
      let time = first.release.time.compare(second.release.time)
      if time == 0 {
        first.release_row.compare(second.release_row)
      } else {
        time
      }
    })
  }
  { reconciliation, continuity, items, }
}
