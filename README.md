# nf-core/porepatrol

**Trim, filter and assess nanopore reads**.

[![Build Status](https://travis-ci.com/nf-core/porepatrol.svg?branch=master)](https://travis-ci.com/nf-core/porepatrol)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker](https://img.shields.io/docker/automated/nfcore/porepatrol.svg)](https://hub.docker.com/r/nfcore/porepatrol)

## Introduction
The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## How can I use nextflow 

* Install nextflow
* Run nextflow: `nextflow run [workflow name]`

## What does porepatrol do

* Input: Basecalled nanopore reads in FASTQ format
* Runs: quality control (nanoplot), trimming adapters (porechop), filtering and trimming (nanofilt). 
* Basic usage is: nextflow run porepatrol --reads "[path to FASTQ reads]"
* Output: trimmed, filtered, FASTQ reads in [what folder?] 
* Note: porepatrol aims to add basecalling functionality if the software becomes available (e.g. Guppy). 

## Documentation
The nf-core/porepatrol pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
3. [Running the pipeline](docs/usage.md)
4. [Output and how to interpret the results](docs/output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

## Credits
nf-core/porepatrol was originally written by Anna Syme.
