///|
pub suberror LedgerInputError {
  InvalidJson
  ExpectedArray
  InvalidField(Int32, String)
}

///|
fn identifier(
  fields : Map[String, Json],
  field : String,
  row : Int32,
) -> String raise LedgerInputError {
  match fields.get(field) {
    Some(String(value)) if !value.trim().is_empty() &&
      value.trim().length() == value.length() => value
    _ => raise InvalidField(row, field)
  }
}

///|
fn read_slip(value : Json, row : Int32) -> Slip raise LedgerInputError {
  guard value is Object(fields) else { raise InvalidField(row, "row") }
  let handoff = identifier(fields, "handoff", row)
  let item = identifier(fields, "item", row)
  let sender = identifier(fields, "sender", row)
  let receiver = identifier(fields, "receiver", row)
  let seal = identifier(fields, "seal", row)
  let time = match fields.get("time") {
    Some(Number(_, repr=Some(literal))) =>
      @string.parse_int64(literal[:]) catch {
        _ => raise InvalidField(row, "time")
      }
    _ => raise InvalidField(row, "time")
  }
  { handoff, item, sender, receiver, seal, time, }
}

///|
/// Decode one JSON ledger. Invalid rows are identified by their position
/// without copying the original contents into an error message.
pub fn decode_ledger(text : StringView) -> Array[Slip] raise LedgerInputError {
  let document = @json.parse(
    text,
    reject_duplicate_keys=true,
    preserve_number_repr=true,
  ) catch {
    _ => raise InvalidJson
  }
  guard document is Array(rows) else { raise ExpectedArray }
  let slips = []
  for index, value in rows {
    slips.push(read_slip(value, index + 1))
  }
  slips
}
