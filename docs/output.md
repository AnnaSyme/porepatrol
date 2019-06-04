# nf-core/porepatrol: Output

This document describes the output produced by the pipeline. 

## Pipeline overview
The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* [Porechop](#porechop) - remove adapters from reads
* [Nanoplot](#nanoplot) - assess quality of reads
* [Nanofilt](#nanofilt) - filter reads according to quality and/or length

**Output directory: `results/pipeline_info`**

[More about Nextflow tracing and visualisation: ](https://www.nextflow.io/docs/latest/tracing.html)

* `results_description.html`
* `pipeline_report.html` and `txt`
* `pipeline_dag.html`
* `execution_report.html`
* `execution_timeline.html`
* `execution_trace.txt`
* `software_versions.csv`

## Porechop
[Porechop](https://github.com/rrwick/Porechop) can chop adapters from nanopore reads. It can also split a read if there is an adapter in the middle. Porechop contains a file with a list of known nanopore adapters. This tool is no longer supported but it still works, and there are no suitable replacements yet. The latest version of the Guppy basecaller will also chop adapters. 

**Output directory: `results/porechop`**

* `chopped.fastq`
  * Fastq reads that have had their adpaters removed. 

## Nanoplot
[Nanoplot](https://github.com/wdecoster/NanoPlot) provides information about your nanopore reads. This is run after adapter trimming, and again after read filtering. You can then compare the results from both analyses. 

**Output directory: `results/nanoplot1 or nanoplot1`**

* `NanoStats.txt`
  * Statistics for the fastq reads: including mean read length and quality, number of reads, total number of bases, etc. 
* `HistogramReadlength`
  * number of reads vs read length
* `LengthvsQualityScatterPlot_dot.png`
  * average read quality vs read length

## Nanofilt
[Nanofilt](https://github.com/wdecoster/nanofilt) filters and trims nanopore reads according to your specifications. 

**Output directory: `results/nanofilt`**

* `filtered.fastq`
  * Fastq reads that have been filtered and/or trimmed.  
