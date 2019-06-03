# nf-core/porepatrol: Output

This document describes the output produced by the pipeline. 

<!-- Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline. -->

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview
The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

* [Porechop](#porechop) - remove adapters from reads
* [Nanoplot](#nanoplot) - assess quality of reads
* [Nanofilt](#nanofilt) - filter reads according to quality and/or length

## Porechop




## Nanoplot
[Nanoplot](https://github.com/wdecoster/NanoPlot) provides information about your fastq reads. This is run after adapter trimming, and after read filtering. You can then compare the results from both analyses. 

**Output directory: `results/nanoplot1 or nanoplot1`**

* `NanoStats.txt`
  * Statistics for the fastq reads: including mean read length and quality, number of reads, total number of bases, etc. 
* `HistogramReadlength`
  * number of reads vs read length
* `LengthvsQualityScatterPlot_dot.png`
  * average read quality vs read length

## Nanofilt

<!-- TODO -->



<!--
## FastQC
[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, the per base sequence content (%T/A/G/C). You get information about adapter contamination and other overrepresented sequences.

For further reading and documentation see the [FastQC help](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality. To see how your reads look after trimming, look at the FastQC reports in the `trim_galore` directory.

**Output directory: `results/fastqc`**

* `sample_fastqc.html`
  * FastQC report, containing quality metrics for your untrimmed raw fastq files
* `zips/sample_fastqc.zip`
  * zip file containing the FastQC report, tab-delimited data file and plot images


## MultiQC
[MultiQC](http://multiqc.info) is a visualisation tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in within the report data directory.

The pipeline has special steps which allow the software versions used to be reported in the MultiQC output for future traceability.

**Output directory: `results/multiqc`**

* `Project_multiqc_report.html`
  * MultiQC report - a standalone HTML file that can be viewed in your web browser
* `Project_multiqc_data/`
  * Directory containing parsed statistics from the different tools used in the pipeline

For more information about how to use MultiQC reports, see [http://multiqc.info](http://multiqc.info)
-->