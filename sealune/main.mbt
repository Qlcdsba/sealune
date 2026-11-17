///|
fn[T] print_error(message : String) -> T {
  println(({ "error": message } : Json).stringify())
  @env.exit(2)
}

///|
fn load(path : String, side : String) -> Array[@ledger.Slip] {
  let bytes = @fs.read_file_to_bytes(path) catch {
    _ => print_error("Could not read the \{side} ledger.")
  }
  let text = @utf8.decode(bytes[:]) catch {
    _ => print_error("The \{side} ledger must contain UTF-8 text.")
  }
  if path.has_suffix(".csv") {
    return load_csv(text[:], side)
  }
  @ledger.decode_ledger(text[:]) catch {
    @ledger.InvalidJson =>
      print_error(
        "The \{side} ledger is not valid JSON or contains a duplicate key.",
      )
    @ledger.ExpectedArray =>
      print_error("The \{side} ledger must be a JSON array.")
    @ledger.InvalidField(row, field) =>
      print_error("The \{side} ledger has an invalid \{field} at row \{row}.")
  }
}

///|
fn load_csv(text : StringView, side : String) -> Array[@ledger.Slip] {
  @ledger.decode_csv_ledger(text) catch {
    @ledger.MalformedCsv(line) =>
      print_error(
        "The \{side} CSV has malformed quoting or a line ending at line \{line}.",
      )
    @ledger.MissingColumn(column) =>
      print_error("The \{side} CSV is missing the \{column} column.")
    @ledger.DuplicateColumn(_) =>
      print_error("The \{side} CSV contains duplicate column names.")
    @ledger.CsvWidth(line, expected, actual) =>
      print_error(
        "The \{side} CSV has \{actual} fields at line \{line}; expected \{expected}.",
      )
    @ledger.InvalidCell(line, column) =>
      print_error("The \{side} CSV has an invalid \{column} at line \{line}.")
  }
}

///|
fn run_item(
  item : String,
  release_path : String,
  receipt_path : String,
) -> Unit {
  let review = @ledger.review(
    load(release_path, "release"),
    load(receipt_path, "receipt"),
  )
  for entry in review.items {
    if entry.item == item {
      println(item_report(review, entry).stringify(indent=2))
      if !entry.issues.is_empty() {
        @env.exit(1)
      }
      return
    }
  }
  print_error("The requested item does not occur in either ledger.")
}

///|
fn run_queue(release_path : String, receipt_path : String) -> Unit {
  let review = @ledger.review(
    load(release_path, "release"),
    load(receipt_path, "receipt"),
  )
  println(make_queue_report(review).stringify(indent=2))
  if !review.reconciliation.findings.is_empty() || !review.continuity.is_empty() {
    @env.exit(1)
  }
}

///|
let usage = "Usage: sealune [--queue | --item ITEM] RELEASES RECEIPTS (JSON or .csv)"

///|
fn main {
  match @env.args() {
    [_, _, "--help"] => println(usage)
    [_, _, "--item", item, release_path, receipt_path] =>
      run_item(item, release_path, receipt_path)
    [_, _, "--queue", release_path, receipt_path] =>
      run_queue(release_path, receipt_path)
    [_, _, release_path, receipt_path] => {
      let releases = load(release_path, "release")
      let receipts = load(receipt_path, "receipt")
      let result = @ledger.reconcile(releases, receipts)
      let gaps = @ledger.check_continuity(result)
      println(make_report(result, gaps).stringify(indent=2))
      if !result.findings.is_empty() || !gaps.is_empty() {
        @env.exit(1)
      }
    }
    _ => print_error(usage)
  }
}
