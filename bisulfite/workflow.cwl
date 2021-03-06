#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "Bisulfite alignment and QC"
requirements:
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement
    - class: ScatterFeatureRequirement
inputs:
    reference_index:
        type: string
    reference_sizes:
        type: File
    instrument_data_bams:
        type: File[]
    read_group_id:
        type: string[]
    sample_name:
        type: string
    trimming_adapters:
        type: File
    trimming_adapter_trim_end:
        type: string
    trimming_adapter_min_overlap:
        type: int
    trimming_max_uncalled:
        type: int
    trimming_min_readlength:
        type: int
outputs:
    cram:
        type: File
        outputSource: bam_to_cram/cram
        secondaryFiles: [.crai, ^.crai]
    vcf:
        type: File
        outputSource: pileup/vcf
    cpgs:
        type: File
        outputSource: vcf2bed/cpgs
    cpg_bedgraph:
        type: File
        outputSource: bedgraph_to_bigwig/cpg_bigwig
steps:
    bam_to_trimmed_fastq_and_biscuit_alignments:
        run: bam_to_trimmed_fastq_and_biscuit_alignments.cwl
        scatter: [bam, read_group_id]
        scatterMethod: dotproduct
        in:
            bam: instrument_data_bams
            read_group_id: read_group_id
            adapters: trimming_adapters
            adapter_trim_end: trimming_adapter_trim_end
            adapter_min_overlap: trimming_adapter_min_overlap
            max_uncalled: trimming_max_uncalled
            min_readlength: trimming_min_readlength
            reference_index: reference_index
        out:
            [aligned_bam]
    merge:
        run: merge.cwl
        in:
            bams: bam_to_trimmed_fastq_and_biscuit_alignments/aligned_bam
        out:
            [merged_bam]
    pileup:
        run: pileup.cwl
        in:
            bam: merge/merged_bam
            reference: reference_index
        out:
            [vcf]
    vcf2bed:
        run: vcf2bed.cwl
        in:
            vcf: pileup/vcf
        out:
            [cpgs,cpg_bedgraph]
    bedgraph_to_bigwig:
        run: bedgraph_to_bigwig.cwl
        in:
            bedgraph: vcf2bed/cpg_bedgraph
            reference_sizes: reference_sizes
        out:
            [cpg_bigwig]
    bam_to_cram:
        run: bam_to_cram.cwl
        in: 
            bam: merge/merged_bam
            reference_index: reference_index
        out:
            [cram]
