cwlVersion: v1.2
class: Workflow
id: kfdrc-cnv-theta2-rerun-workflow
label: KFDRC CNV and THeTa2 Rerun Workflow
doc: |
  Rerun the Control-FREEC, CNVkit, and THeTa2 portions of the somatic workflow
  without rerunning VarDict. THeTa2 uses the supplied paired VarDict prepass VCF.

  When the aligned inputs are CRAMs, this workflow first converts them to BAM and
  recalculates MD tags, matching the behavior of the parent somatic workflow.
  A germline `b_allele` VCF is optional, but recommended for B-allele-frequency
  and LOH-aware CNV calling. If it is supplied, it is restricted to the CNV
  regions and hard-filtered before use by Control-FREEC and CNVkit.

requirements:
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement

inputs:
  input_tumor_aligned:
    type: File
    secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false}, {pattern: "^.crai", required: false}]
    doc: Tumor BAM or CRAM and its index.
  input_normal_aligned:
    type: File
    secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false}, {pattern: "^.crai", required: false}]
    doc: Matched-normal BAM or CRAM and its index.
  input_tumor_name: {type: string}
  input_normal_name: {type: string}
  indexed_reference_fasta:
    type: File
    secondaryFiles: [{pattern: ".fai", required: true}, {pattern: "^.dict", required: true}]
    "sbg:suggestedValue":
      class: File
      path: 60639014357c3a53540ca7a3
      name: Homo_sapiens_assembly38.fasta
      secondaryFiles:
        - {class: File, path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai}
        - {class: File, path: 60639019357c3a53540ca7e7, name: Homo_sapiens_assembly38.dict}
    doc: Reference FASTA with FAI and sequence dictionary.
  calling_regions: {type: File, doc: BED or interval-list regions to analyze.}
  cnv_blacklist_regions:
    type: File?
    doc: Regions to exclude from CNV calling.
    "sbg:suggestedValue": {class: File, path: 663d2bcc27374715fccd8c6d,
      name: somatic-hg38_CNV_and_centromere_blacklist.hg38liftover.list}
  wgs_or_wxs:
    type: {type: enum, name: wgs_or_wxs, symbols: [WGS, WXS]}
  output_basename: {type: string}
  run_calmd_bam: {type: 'boolean?', default: false, doc: Force calmd even when an input is BAM.}
  cfree_ploidy: {type: 'int[]', doc: Ploidy possibilities for Control-FREEC.}
  cfree_threads: {type: 'int?', default: 16}
  cfree_mate_orientation_control:
    type: ['null', {type: enum, name: mate_orientation_control, symbols: ["0", FR, RF, FF]}]
    default: FR
  cfree_mate_orientation_sample:
    type: ['null', {type: enum, name: mate_orientation_sample, symbols: ["0", FR, RF, FF]}]
    default: FR
  cfree_coeff_var: {type: 'float?', default: 0.05}
  cfree_contamination_adjustment: {type: 'boolean?'}
  cfree_sex:
    type: ['null', {type: enum, name: cfree_sex, symbols: [XX, XY]}]
    default: XX
  cnvkit_annotation_file:
    type: File
    doc: refFlat annotation file.
    "sbg:suggestedValue": {class: File, path: 5f500135e4b0370371c051c1,
      name: refFlat_HG38.txt}
  cnvkit_sex:
    type: ['null', {type: enum, name: cnvkit_sex, symbols: [x, y]}]
    default: x
  cnvkit_wgs_mode: {type: 'string?', doc: Set to Y for WGS; inferred from wgs_or_wxs when omitted.}
  i_flag: {type: 'string?', doc: Set to N to skip intersecting the germline VCF; defaults to N for WGS.}

  b_allele:
    type: File?
    secondaryFiles: [{pattern: ".tbi", required: true}]
    doc: Optional germline VCF for BAF estimation.
  vardict_prepass_vcf:
    type: File
    secondaryFiles: [{pattern: ".tbi", required: false}, {pattern: ".csi", required: false}]
    doc: Existing paired VarDict prepass VCF used by THeTa2; VarDict is not rerun.
  combined_include_expression:
    type: string?
    default: 'FILTER="PASS" && (INFO/STATUS="Germline" | INFO/STATUS="StrongSomatic")'
  combined_exclude_expression: {type: 'string?'}
  min_theta2_frac: {type: 'float?', default: 0.01}

outputs:
  ctrlfreec_pval: {type: File, outputSource: controlfreec/ctrlfreec_pval}
  ctrlfreec_config: {type: File, outputSource: controlfreec/ctrlfreec_config}
  ctrlfreec_pngs: {type: 'File[]', outputSource: controlfreec/ctrlfreec_pngs}
  ctrlfreec_bam_ratio: {type: File, outputSource: controlfreec/ctrlfreec_bam_ratio}
  ctrlfreec_bam_seg: {type: File, outputSource: controlfreec/ctrlfreec_bam_seg}
  ctrlfreec_baf: {type: 'File?', outputSource: controlfreec/ctrlfreec_baf}
  ctrlfreec_info: {type: File, outputSource: controlfreec/ctrlfreec_info}
  cnvkit_cnr: {type: File, outputSource: cnvkit/cnvkit_cnr}
  cnvkit_cnn_output: {type: 'File?', outputSource: cnvkit/cnvkit_cnn_output}
  cnvkit_calls: {type: File, outputSource: cnvkit/cnvkit_calls}
  cnvkit_metrics: {type: File, outputSource: cnvkit/cnvkit_metrics}
  cnvkit_gainloss: {type: File, outputSource: cnvkit/cnvkit_gainloss}
  cnvkit_seg: {type: File, outputSource: cnvkit/cnvkit_seg}
  cnvkit_scatter_plot: {type: File, outputSource: cnvkit/cnvkit_scatter_plot}
  cnvkit_diagram: {type: File, outputSource: cnvkit/cnvkit_diagram}
  theta2_calls: {type: 'File?', outputSource: theta2_purity/theta2_adjusted_cns}
  theta2_seg: {type: 'File?', outputSource: theta2_purity/theta2_adjusted_seg}
  theta2_subclonal_results: {type: ['null', 'File[]'], outputSource: expression_flatten_subclonal_results/output}
  theta2_subclonal_cns: {type: ['null', 'File[]'], outputSource: theta2_purity/theta2_subclonal_cns}
  theta2_subclone_seg: {type: ['null', 'File[]'], outputSource: theta2_purity/theta2_subclone_seg}

steps:
  samtools_cram2bam_plus_calmd_tumor:
    run: ../tools/samtools_calmd.cwl
    when: $(inputs.input_reads.basename.search(/.cram$/) != -1 || inputs.run_anyway)
    in:
      input_reads: input_tumor_aligned
      run_anyway: run_calmd_bam
      threads: {valueFrom: $(16)}
      reference: indexed_reference_fasta
    out: [bam_file]
  samtools_cram2bam_plus_calmd_normal:
    run: ../tools/samtools_calmd.cwl
    when: $(inputs.input_reads.basename.search(/.cram$/) != -1 || inputs.run_anyway)
    in:
      input_reads: input_normal_aligned
      reference: indexed_reference_fasta
      run_anyway: run_calmd_bam
      threads: {valueFrom: $(16)}
    out: [bam_file]
  prepare_regions_unpadded_cnv:
    run: ../sub_workflows/prepare_regions.cwl
    in:
      reference_dict:
        source: indexed_reference_fasta
        valueFrom: $(self.secondaryFiles.filter(function(e) { return e.basename.search(/.dict$/) != -1 })[0])
      calling_regions: calling_regions
      blacklist_regions: cnv_blacklist_regions
      scatter_count: {valueFrom: $(0)}
    out: [prescatter_bed]
  mode_defaults:
    run: ../tools/mode_defaults.cwl
    in:
      input_mode: wgs_or_wxs
      cnvkit_wgs_mode: cnvkit_wgs_mode
      i_flag: i_flag
    out: [out_cnvkit_wgs_mode, out_i_flag]
  bedtools_intersect_germline:
    run: ../tools/bedtools_intersect.cwl
    when: $(inputs.input_vcf != null)
    in:
      input_vcf: b_allele
      input_bed_file: prepare_regions_unpadded_cnv/prescatter_bed
      output_basename: output_basename
      flag: mode_defaults/out_i_flag
    out: [intersected_vcf]
  gatk_filter_germline:
    run: ../tools/gatk_filter_germline_variant.cwl
    when: $(inputs.input_vcf != null)
    in:
      input_vcf: bedtools_intersect_germline/intersected_vcf
      reference_fasta: indexed_reference_fasta
      output_basename: output_basename
    out: [filtered_vcf, filtered_pass_vcf]
  controlfreec:
    run: ../sub_workflows/kfdrc_controlfreec_sub_wf.cwl
    in:
      input_tumor_aligned:
        source: [samtools_cram2bam_plus_calmd_tumor/bam_file, input_tumor_aligned]
        pickValue: first_non_null
      input_tumor_name: input_tumor_name
      input_normal_aligned:
        source: [samtools_cram2bam_plus_calmd_normal/bam_file, input_normal_aligned]
        pickValue: first_non_null
      wgs_or_wxs: wgs_or_wxs
      threads: cfree_threads
      output_basename: output_basename
      ploidy: cfree_ploidy
      mate_orientation_sample: cfree_mate_orientation_sample
      mate_orientation_control: cfree_mate_orientation_control
      calling_regions: prepare_regions_unpadded_cnv/prescatter_bed
      indexed_reference_fasta: indexed_reference_fasta
      b_allele: gatk_filter_germline/filtered_pass_vcf
      coeff_var: cfree_coeff_var
      contamination_adjustment: cfree_contamination_adjustment
      cfree_sex: cfree_sex
    out: [ctrlfreec_pval, ctrlfreec_config, ctrlfreec_pngs, ctrlfreec_bam_ratio, ctrlfreec_bam_seg, ctrlfreec_baf, ctrlfreec_info]
  cnvkit:
    run: ../sub_workflows/kfdrc_cnvkit_sub_wf.cwl
    in:
      input_tumor_aligned:
        source: [samtools_cram2bam_plus_calmd_tumor/bam_file, input_tumor_aligned]
        pickValue: first_non_null
      tumor_sample_name: input_tumor_name
      input_normal_aligned:
        source: [samtools_cram2bam_plus_calmd_normal/bam_file, input_normal_aligned]
        pickValue: first_non_null
      reference: indexed_reference_fasta
      normal_sample_name: input_normal_name
      capture_regions: prepare_regions_unpadded_cnv/prescatter_bed
      blacklist_regions: cnv_blacklist_regions
      wgs_mode: mode_defaults/out_cnvkit_wgs_mode
      b_allele_vcf: gatk_filter_germline/filtered_pass_vcf
      annotation_file: cnvkit_annotation_file
      output_basename: output_basename
      sex: cnvkit_sex
    out: [cnvkit_cnr, cnvkit_cnn_output, cnvkit_cns, cnvkit_calls, cnvkit_metrics, cnvkit_gainloss, cnvkit_seg, cnvkit_scatter_plot, cnvkit_diagram]
  theta2_purity:
    run: ../sub_workflows/kfdrc_run_theta2_sub_wf.cwl
    in:
      tumor_cns: cnvkit/cnvkit_calls
      reference_cnn: cnvkit/cnvkit_cnn_output
      tumor_sample_name: input_tumor_name
      normal_sample_name: input_normal_name
      paired_vcf: vardict_prepass_vcf
      combined_include_expression: combined_include_expression
      combined_exclude_expression: combined_exclude_expression
      min_theta2_frac: min_theta2_frac
      output_basename: output_basename
    out: [theta2_adjusted_cns, theta2_adjusted_seg, theta2_subclonal_results, theta2_subclonal_cns, theta2_subclone_seg]
  expression_flatten_subclonal_results:
    run: ../tools/expression_flatten_file_list.cwl
    when: $(inputs.input_list != null)
    in:
      input_list: theta2_purity/theta2_subclonal_results
    out: [output]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: "sbg:maxNumberOfParallelInstances"
  value: 6
"sbg:license": Apache License 2.0
"sbg:publisher": KFDRC
"sbg:categories":
- BAM
- CNV
- CNVKIT
- CONTROLFREEC
- CRAM
- THETA2
- VCF
"sbg:links":
- id: 'https://github.com/childrens-bti/kf-somatic-workflow-cnh/releases/tag/v1.0.0'
  label: github-release
