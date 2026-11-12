///|
/// One row from a release or receipt ledger. Times are UTC Unix seconds.
pub(all) struct Slip {
  handoff : String
  item : String
  sender : String
  receiver : String
  seal : String
  time : Int64
}

///|
#derive(Eq, Debug)
pub(all) enum PairFault {
  MissingRelease
  MissingReceipt
  DuplicateRelease
  DuplicateReceipt
  ItemMismatch
  SenderMismatch
  ReceiverMismatch
  SealMismatch
  ReceiptBeforeRelease
}

///|
/// Source row numbers are one-based within their respective input arrays.
#derive(Eq, Debug)
pub(all) struct Finding {
  handoff : String
  fault : PairFault
  releases : Array[Int32]
  receipts : Array[Int32]
}

///|
pub(all) struct Match {
  release : Slip
  receipt : Slip
  release_row : Int32
  receipt_row : Int32
}

///|
pub(all) struct Reconciliation {
  matches : Array[Match]
  findings : Array[Finding]
}

///|
priv struct Bucket {
  releases : Array[Int32]
  receipts : Array[Int32]
}

///|
fn bucket_for(
  buckets : Map[String, Bucket],
  order : Array[String],
  handoff : String,
) -> Bucket {
  match buckets.get(handoff) {
    Some(bucket) => bucket
    None => {
      let bucket = { releases: [], receipts: [], }
      buckets[handoff] = bucket
      order.push(handoff)
      bucket
    }
  }
}

///|
/// Match unique release and receipt rows by handoff ID. A pair only enters
/// the result when the two rows agree and the receipt is chronologically valid.
pub fn reconcile(
  releases : Array[Slip],
  receipts : Array[Slip],
) -> Reconciliation {
  let buckets : Map[String, Bucket] = Map([])
  let order = []
  for index, slip in releases {
    bucket_for(buckets, order, slip.handoff).releases.push(index + 1)
  }
  for index, slip in receipts {
    bucket_for(buckets, order, slip.handoff).receipts.push(index + 1)
  }
  let matches = []
  let findings = []
  for handoff in order {
    let bucket = buckets[handoff]
    let faults = []
    match (bucket.releases, bucket.receipts) {
      ([release_row], [receipt_row]) => {
        let release = releases[release_row - 1]
        let receipt = receipts[receipt_row - 1]
        if release.item != receipt.item {
          faults.push(ItemMismatch)
        }
        if release.sender != receipt.sender {
          faults.push(SenderMismatch)
        }
        if release.receiver != receipt.receiver {
          faults.push(ReceiverMismatch)
        }
        if release.seal != receipt.seal {
          faults.push(SealMismatch)
        }
        if receipt.time < release.time {
          faults.push(ReceiptBeforeRelease)
        }
        if faults.is_empty() {
          matches.push({ release, receipt, release_row, receipt_row, })
        }
      }
      _ => {
        if bucket.releases.is_empty() {
          faults.push(MissingRelease)
        }
        if bucket.receipts.is_empty() {
          faults.push(MissingReceipt)
        }
        if bucket.releases.length() > 1 {
          faults.push(DuplicateRelease)
        }
        if bucket.receipts.length() > 1 {
          faults.push(DuplicateReceipt)
        }
      }
    }
    for fault in faults {
      findings.push({
        handoff,
        fault,
        releases: bucket.releases.copy(),
        receipts: bucket.receipts.copy(),
      })
    }
  }
  { matches, findings, }
}

///|
pub extend PairFault with Eq::{not_equal, equal}

///|
pub extend PairFault with @debug.Debug::{to_repr}

///|
pub extend Finding with Eq::{not_equal, equal}

///|
pub extend Finding with @debug.Debug::{to_repr}
