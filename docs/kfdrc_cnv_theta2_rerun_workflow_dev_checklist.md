# CNV and THeTa2 Rerun Wrapper Development Checklist

This checklist follows the [workflow development, prioritization, and release standard](https://github.com/childrens-bti/internal-ticket-tracker/issues/1168).

Use this checklist when proposing a workflow, materially changing its scope, or
preparing it for release. It provides a consistent record of why the workflow
is supported, how it was validated, and who will maintain it. Complete only the
items that apply to the intended release class, and record any exceptions in the
pull request or release notes.

> **Existing workflows and wrappers:** This checklist also applies to an
> existing workflow, subworkflow, or rerun wrapper. It is not evidence that the
> component is a brand-new workflow. For this path, document the parent
> workflow, the changed or reused behavior, and validation of the delta; do not
> repeat discovery or prioritization work that is already documented for the
> parent workflow.

## Lifecycle and release classes

| Stage | Purpose | Release expectation |
| --- | --- | --- |
| Experimental / prototype | Evaluate an approach or produce preliminary results. | Named owner, limited audience, and clearly documented limitations. Not supported as a production service. |
| Internal production | Deliver reproducible analyses for defined internal users or projects. | Versioned source, documented interface and references, validation evidence, operational owner, and a maintenance plan. |
| Publicly released / community supported | Provide a stable workflow for external use. | Meets internal-production requirements plus public documentation, a release/versioning plan, license and provenance review, public support expectations, and reproducible example or test data where sharing is permitted. |

## Prioritization

Before starting a net-new workflow, record the expected level of demand,
scientific or clinical impact, strategic relevance, availability of alternatives,
implementation and maintenance cost, and data/infrastructure readiness. Use the
record to choose a lifecycle stage and owner. A higher expected benefit does not
remove the need to identify maintenance capacity.

## Development checklist

### Scope and ownership

- [ ] State the scientific use case, target users, and intended lifecycle stage.
- [ ] Identify the accountable owner and review/maintenance contacts.
- [ ] Identify upstream tools, reference data, licenses, and version constraints.
- [ ] State expected compute, storage, platform, and access requirements.
- [ ] For a wrapper or existing workflow, identify the parent workflow and the
      behavior that is reused or changed.

### Implementation and validation

- [ ] Keep the workflow interface explicit: inputs, optionality, defaults,
      secondary files, outputs, and failure conditions are documented.
- [ ] Pin or otherwise record tool and reference versions needed for
      reproducibility.
- [ ] Validate CWL syntax and run the narrowest practical representative test.
- [ ] Define relevant QC outputs, benchmark comparison, or acceptance metrics;
      record the test dataset and results where they may be shared.
- [ ] Review error handling, resource/concurrency settings, sensitive-data
      handling, and compatibility with the target execution platform.

### Documentation and release

- [ ] Add user-facing documentation covering purpose, inputs, outputs, required
      references, defaults, limitations, and local/platform execution.
- [ ] Add workflow metadata appropriate to the target platform, including label,
      publisher, license, categories, and release or source link.
- [ ] Document the release class, versioning approach, known limitations, and
      support/maintenance expectations.
- [ ] For public release, complete a public-data, security, license, and support
      review and provide a reproducible public example when feasible.

## CNV and THeTa2 rerun wrapper alignment

The [`kfdrc-cnv-theta2-rerun-workflow`](../workflow/kfdrc-cnv-theta2-rerun-workflow.cwl)
is an **existing-workflow wrapper**, not a net-new analysis workflow. It reuses
the production somatic workflow's Control-FREEC, CNVkit, and THeTa2 components
to rerun CNV analysis from tumor/normal alignments and an existing paired
VarDict prepass VCF. Its parent behavior and required inputs are documented in
the [repository README](../README.md#cnv-and-theta2-rerun-workflow).

- [x] The wrapper's scope, reused components, required VarDict input, and
      WGS/WXS behavior are documented.
- [x] Inputs expose types, optionality, defaults, secondary files, and
      CAVATICA suggested reference values where available.
- [x] Outputs and CAVATICA metadata are documented in the CWL.
- [x] User-facing inputs, references, and local validation are documented in
      the README.
- [ ] Run and record representative WGS and WXS validation datasets before a
      production or public release decision.
- [ ] Confirm the release class, accountable maintainer, support channel, and
      release version when the wrapper is promoted beyond its current
      development status.
