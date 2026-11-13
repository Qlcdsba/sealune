# Source and license notes

Sealune is an original implementation. Its exercise ledgers and expected results use invented items, roles, seals, and timestamps. The crescent mark was created for this project. No real case file or third-party fixture is included.

| Dependency | Use | License |
| --- | --- | --- |
| [MoonBit Core](https://github.com/moonbitlang/core) | Collections, exact JSON parsing, UTF-8 decoding, and runtime arguments | Apache-2.0 |
| [moonbitlang/x](https://github.com/moonbitlang/x) | Local file reads in the CLI | Apache-2.0 |
| [actions/checkout](https://github.com/actions/checkout) | CI checkout | MIT |
| [hustcer/setup-moonbit](https://github.com/hustcer/setup-moonbit) | CI toolchain installation | MIT |

The repository's own code and examples are distributed under the [MIT license](LICENSE). The generated MoonBit interface is produced from the library source by `moon info`.
