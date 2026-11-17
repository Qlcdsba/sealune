///|
test "CSV reads reordered fields, CRLF, quoted commas and doubled quotes" {
  let text = "time,seal,item,receiver,sender,handoff,notes\r\n-10,\"S,\"\"4\"\"\",物件,store,field,T-1,\"two\r\nlines\""
  let slips = @ledger.decode_csv_ledger(text[:])
  assert_eq(slips[0].seal, "S,\"4\"")
  assert_eq(slips[0].item, "物件")
  assert_eq(slips[0].time, -10L)
}

///|
test "CSV diagnoses physical lines after a multiline field" {
  let text = "handoff,item,sender,receiver,seal,time,notes\nA,P,F,S,1,0,\"one\ntwo\"\nB,P,F,S,1,4.2,none"
  let error = try {
    ignore(@ledger.decode_csv_ledger(text[:]))
    None
  } catch {
    error => Some(error)
  }
  assert_true(error is Some(@ledger.InvalidCell(4, "time")))
}

///|
test "CSV rejects duplicate headings and unfinished quotes" {
  let duplicate = "handoff,handoff"
  let first = try {
    ignore(@ledger.decode_csv_ledger(duplicate[:]))
    None
  } catch {
    error => Some(error)
  }
  assert_true(first is Some(@ledger.DuplicateColumn("handoff")))
  let second = try {
    ignore(@ledger.decode_csv_ledger("\"handoff"))
    None
  } catch {
    error => Some(error)
  }
  assert_true(second is Some(@ledger.MalformedCsv(1)))
}
