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
fn main {
  match @env.args() {
    [_, _, "--help"] => println("Usage: sealune RELEASES.json RECEIPTS.json")
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
    _ => print_error("Usage: sealune RELEASES.json RECEIPTS.json")
  }
}
