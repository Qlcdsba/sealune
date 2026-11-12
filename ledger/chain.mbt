///|
#derive(Eq, Debug)
pub(all) enum ChainFault {
  AmbiguousOrder
  OverlappingCustody
  CustodianMismatch
}

///|
pub extend ChainFault with Eq::{not_equal, equal}

///|
pub extend ChainFault with @debug.Debug::{to_repr}

///|
pub(all) struct ChainFinding {
  item : String
  fault : ChainFault
  first : Match
  second : Match
}

///|
/// Compare consecutive confirmed handoffs for each item. Tied release
/// times are reported as ambiguous, and comparisons touching a tied
/// group are skipped because its boundary handoffs are unknown.
pub fn check_continuity(result : Reconciliation) -> Array[ChainFinding] {
  let by_item : Map[String, Array[Match]] = Map([])
  let items = []
  for pair in result.matches {
    let item = pair.release.item
    match by_item.get(item) {
      Some(pairs) => pairs.push(pair)
      None => {
        by_item[item] = [pair]
        items.push(item)
      }
    }
  }
  let findings = []
  for item in items {
    let pairs = by_item[item]
    pairs.sort_by((a, b) => {
      let by_time = a.release.time.compare(b.release.time)
      if by_time == 0 {
        a.release_row.compare(b.release_row)
      } else {
        by_time
      }
    })
    for index in 1..<pairs.length() {
      let first = pairs[index - 1]
      let second = pairs[index]
      let first_time = first.release.time
      let second_time = second.release.time
      if first_time == second_time {
        findings.push({ item, fault: AmbiguousOrder, first, second, })
        continue
      }
      let first_is_tied = index >= 2 &&
        pairs[index - 2].release.time == first_time
      let second_is_tied = index + 1 < pairs.length() &&
        pairs[index + 1].release.time == second_time
      if first_is_tied || second_is_tied {
        continue
      }
      if first.receipt.time > second_time {
        findings.push({ item, fault: OverlappingCustody, first, second, })
      }
      if first.receipt.receiver != second.release.sender {
        findings.push({ item, fault: CustodianMismatch, first, second, })
      }
    }
  }
  findings
}
