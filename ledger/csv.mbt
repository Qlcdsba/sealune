///|
pub suberror CsvLedgerError {
  MalformedCsv(Int32)
  MissingColumn(String)
  DuplicateColumn(String)
  CsvWidth(Int32, Int32, Int32)
  InvalidCell(Int32, String)
}

///|
priv enum CsvState {
  Start
  Unquoted
  Quoted
  AfterQuote
}

///|
priv struct CsvRecord {
  line : Int32
  fields : Array[String]
}

///|
priv struct CsvReader {
  records : Array[CsvRecord]
  field : StringBuilder
  mut fields : Array[String]
  mut state : CsvState
  mut line : Int32
  mut record_line : Int32
  mut pending_cr : Bool
}

///|
fn CsvReader::finish_field(self : CsvReader) -> Unit {
  self.fields.push(self.field.to_string())
  self.field.reset()
  self.state = Start
}

///|
fn CsvReader::finish_record(self : CsvReader) -> Unit {
  self.finish_field()
  self.records.push({ line: self.record_line, fields: self.fields, })
  self.fields = []
  self.record_line = self.line + 1
}

///|
fn CsvReader::newline(self : CsvReader) -> Unit {
  if self.state is Quoted {
    self.field.write_char('\n')
  } else {
    self.finish_record()
  }
  self.line += 1
}

///|
fn CsvReader::accept(self : CsvReader, ch : Char) -> Unit raise CsvLedgerError {
  if self.pending_cr {
    self.pending_cr = false
    guard ch == '\n' else { raise MalformedCsv(self.line) }
    self.newline()
    return
  }
  match ch {
    '\r' => self.pending_cr = true
    '\n' => self.newline()
    _ =>
      match (self.state, ch) {
        (Quoted, '"') => self.state = AfterQuote
        (Quoted, _) => self.field.write_char(ch)
        (AfterQuote, '"') => {
          self.field.write_char('"')
          self.state = Quoted
        }
        (_, ',') => self.finish_field()
        (Start, '"') => self.state = Quoted
        (AfterQuote, _) | (Unquoted, '"') => raise MalformedCsv(self.line)
        _ => {
          self.field.write_char(ch)
          self.state = Unquoted
        }
      }
  }
}

///|
fn parse_csv(text : StringView) -> Array[CsvRecord] raise CsvLedgerError {
  let reader : CsvReader = {
    records: [],
    field: StringBuilder(),
    fields: [],
    state: Start,
    line: 1,
    record_line: 1,
    pending_cr: false,
  }
  for ch in text {
    reader.accept(ch)
  }
  if reader.pending_cr || reader.state is Quoted {
    raise MalformedCsv(reader.line)
  }
  if !reader.fields.is_empty() || !(reader.state is Start) {
    reader.finish_record()
  }
  reader.records
}

///|
let required_columns : Array[String] = [
  "handoff", "item", "sender", "receiver", "seal", "time",
]

///|
fn header_index(header : CsvRecord) -> Map[String, Int32] raise CsvLedgerError {
  let index : Map[String, Int32] = Map([])
  for position, name in header.fields {
    if index.get(name) is Some(_) {
      raise DuplicateColumn(name)
    }
    index[name] = position
  }
  for name in required_columns {
    guard index.get(name) is Some(_) else { raise MissingColumn(name) }
  }
  index
}

///|
fn csv_identifier(
  record : CsvRecord,
  index : Map[String, Int32],
  name : String,
) -> String raise CsvLedgerError {
  let value = record.fields[index[name]]
  if value.trim().is_empty() ||
    value.trim().length() != value.length() ||
    value.contains("\n") {
    raise InvalidCell(record.line, name)
  }
  value
}

///|
fn csv_time(
  record : CsvRecord,
  index : Map[String, Int32],
) -> Int64 raise CsvLedgerError {
  let literal = record.fields[index["time"]]
  let mut digits = 0
  for position, ch in literal {
    if position == 0 && ch == '-' {
      continue
    }
    if ch < '0' || ch > '9' {
      raise InvalidCell(record.line, "time")
    }
    digits += 1
  }
  if digits == 0 {
    raise InvalidCell(record.line, "time")
  }
  @string.parse_int64(literal[:], base=10) catch {
    _ => raise InvalidCell(record.line, "time")
  }
}

///|
/// Decode a header-based CSV. Findings use one-based data record indices.
/// Input errors use physical line numbers and include the header.
pub fn decode_csv_ledger(text : StringView) -> Array[Slip] raise CsvLedgerError {
  let records = parse_csv(text)
  guard records is [header, .. rows] else { raise MissingColumn("handoff") }
  let index = header_index(header)
  let slips = []
  for record in rows {
    let expected = header.fields.length()
    let actual = record.fields.length()
    if expected != actual {
      raise CsvWidth(record.line, expected, actual)
    }
    slips.push({
      handoff: csv_identifier(record, index, "handoff"),
      item: csv_identifier(record, index, "item"),
      sender: csv_identifier(record, index, "sender"),
      receiver: csv_identifier(record, index, "receiver"),
      seal: csv_identifier(record, index, "seal"),
      time: csv_time(record, index),
    })
  }
  slips
}
