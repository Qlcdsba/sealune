# Storage and lab intake exercise

The field team and the receiving desks exported their slips separately. The receiving desk sorted some slips in a different order.

| Handoff | Release row | Receipt row(s) | Expected review |
| --- | ---: | ---: | --- |
| T-01 | 1 | 2 | Pair agrees. Storage signed for P-14. |
| T-02 | 2 | 1 | Pair agrees. Intake sent P-14 to the lab, but T-01 records storage as the previous receiver. Check for an omitted movement from storage to intake. |
| T-03 | 3 | — | No receipt for P-22. |
| T-04 | 4 | 3 | P-35 has seal S-054 on release and S-045 on receipt. |
| T-05 | 5 | 4, 5 | Two receipts share the same handoff ID. The reviewer must decide which, if either, belongs to this release. |
| T-06 | 6 | 7 | Pair agrees. Storage signed for P-51. |
| T-07 | 7 | 6 | Pair agrees. Storage sent P-51 to the lab after receiving it. |

The expected report has four matches, three pair findings, and one continuity finding. The command returns exit code 1 because the exercise includes discrepancies.

## Two other uses for the same library

**Laboratory sample retention.** A preparation bench transfers a sealed retention sample to cold storage. Each desk exports its own slip. If the bench recorded seal `S-054` and storage recorded `S-045`, Sealune points to the two rows with `seal_mismatch`. The lab supervisor checks the seal on the sample against both original records before correcting the register. The P-35 exercise rows reproduce this situation.

**Archive loan.** A records room releases an original file to a reading desk. A later pair records a scanning desk releasing that same file back to storage. Both pairs agree internally, but the earlier receipt ends at the reading desk. Sealune flags `custodian_mismatch` across both pairs so the archivist can find a missing intermediate receipt or correct the desk identifier. The P-14 exercise rows reproduce this handoff pattern.
