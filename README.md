<img src="sealune-mark.svg" alt="Sealune" width="72" height="72">

# Sealune

**Match handoff records. Find custody gaps.**

Sealune reconciles two independently kept records of physical custody: the release ledger and the receipt ledger. Each handoff carries an ID, item ID, sender, receiver, seal ID, and timestamp. The library flags discrepancies and returns the source rows for follow-up.

Once two slips agree, Sealune can compare consecutive handoffs for that item. It flags a different custodian, an outgoing handoff recorded before the previous receipt, and tied release times whose order needs human review. Unmatched slips are reported separately. A gap between confirmed handoffs can point to a missing record.

## Try the training exercise

Install [MoonBit](https://www.moonbitlang.com/download) and Node.js, then clone the repository and initialize the MoonBit registry index:

```sh
git clone https://github.com/Qlcdsba/sealune.git
cd sealune
moon update
```

Run the exercise from the repository root:

```sh
moon run sealune --target js -- exercise/releases.json exercise/receipts.json
```

The exercise follows fictional exhibits through a field team, storage, and a lab. It deliberately includes a missing receipt, a conflicting seal, a duplicated receipt, and a break in custody. Compare the report with [the exercise notes](exercise/README.md).

## Ledger format

Supply a UTF-8 JSON array for each side. Each row has the same fields:

```json
{"handoff":"T-01","item":"P-14","sender":"field","receiver":"store","seal":"S-017","time":1794445200}
```

Use a common handoff ID across the two ledgers and a unique ID for each transfer. Identifiers are case-sensitive, nonblank strings without surrounding whitespace. Use signed integer Unix seconds (UTC) for `time`. The program rejects duplicate object keys and invalid fields. Unknown fields are ignored.

The report includes matched handoffs, pair findings, and continuity findings. Row numbers start at 1 in each input array. The CLI returns **0** for a clean report, **1** for findings, and **2** for unreadable or invalid input. It reads locally and writes JSON to standard output. Its findings describe recorded discrepancies. A matching pair does not authenticate either ledger or establish what happened in the field.

## Use from MoonBit

Import `Qlcdsba/sealune/ledger`. Pass text to `decode_ledger`, pass the two decoded arrays to `reconcile`, and pass that result to `check_continuity`. The library can also accept typed slips directly and makes no filesystem calls.

```sh
moon fmt --check
moon check --deny-warn --target js
moon test --deny-warn --target js
moon test --deny-warn --target wasm-gc
moon build --target js
```

The participant set the investigation-training use case, approved the project direction and name, and specified staged delivery. AI assisted with implementation, fixtures, tests, and documentation. The exercise records are fictional.
