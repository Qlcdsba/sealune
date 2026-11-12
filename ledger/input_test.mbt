///|
test "read exact integer seconds without floating-point rounding" {
  let text =
    #|[{"handoff":"A","item":"P","sender":"field","receiver":"store","seal":"S","time":9007199254740993}]
  let slips = @ledger.decode_ledger(text[:])
  debug_inspect(slips[0].time, content="9007199254740993")
}

///|
fn input_error(text : String) -> @ledger.LedgerInputError? {
  try {
    ignore(@ledger.decode_ledger(text[:]))
    None
  } catch {
    error => Some(error)
  }
}

///|
test "reject duplicate object keys before attempting reconciliation" {
  let text =
    #|[{"handoff":"A","handoff":"B"}]
  assert_true(input_error(text) is Some(@ledger.InvalidJson))
}

///|
test "identify a non-integer timestamp by row and field" {
  let text =
    #|[{"handoff":"A","item":"P","sender":"field","receiver":"store","seal":"S","time":3.5}]
  assert_true(input_error(text) is Some(@ledger.InvalidField(1, "time")))
}

///|
test "reject an identifier padded with whitespace" {
  let text =
    #|[{"handoff":"A ","item":"P","sender":"field","receiver":"store","seal":"S","time":10}]
  assert_true(input_error(text) is Some(@ledger.InvalidField(1, "handoff")))
}
