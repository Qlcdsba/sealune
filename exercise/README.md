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
