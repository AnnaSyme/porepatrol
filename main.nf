#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-core/porepatrol
========================================================================================
 nf-core/porepatrol Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nf-core/porepatrol
----------------------------------------------------------------------------------------
*/


/*
========================================================================================
                         The main inputs and processes
========================================================================================
*/


/* If input file is gzipped, unzip */
/* set into input channel */


if ("${params.reads}".endsWith(".gz")) {
 //Put the zip into a channel, then unzip it and forward to downstream processes.

    gzipped_fastq = file("${params.reads}")
    rm_gz = params.reads - '.gz' //remove extension first

    process unzip_inputfiles {

        input:
        file gzipped_fastq

        output:
        file "*.{fq,fastq}" into ch_input

        script:
        """
        gunzip -f $gzipped_fastq
        """
        }
    }
    else {
        Channel
            .fromPath(params.reads)
            .set { ch_input }

}


/* Collect multiple input files */

process concat_fastqs {
    echo true
    publishDir "${params.outdir}/concatfastqs", mode: 'copy'

    input:
    file "nanoplot0/*"
    file fastq from ch_input.collect()  //need to collect all files from input

    output:
    file "inputs.fastq" into ch_fastq_porechop
    file "num_reads_start.txt" into ch1
    file "num_bases_start.txt" into ch2

    script:
    """
    cat $fastq > inputs.fastq

    NanoPlot --fastq inputs.fastq -o nanoplot0

    #print line 6: number of reads
    numreads=\$(echo \$(sed -n 6p nanoplot0/NanoStats.txt))
    echo Input: \$numreads > num_reads_start.txt

    #print line 8: number of bases
    numbases=\$(echo \$(sed -n 8p nanoplot0/NanoStats.txt))
    echo Input: \$numbases > num_bases_start.txt
    """
}

/* Chop adapters */

process porechop {
    publishDir "${params.outdir}/porechop", mode: 'copy'

    input:
    file fastq from ch_fastq_porechop  //change these x to be more meaningful

    output:
    file "chopped.fastq" into ch_fastq_nanoplot, ch_fastq_nanofilt

    script:
    //porechop expects fastq files
    //unable to give process gzipped file as gzip won't work in nextflow
    //considers the input file "not a regular file"

    """
    porechop -i $fastq -o chopped.fastq
    """
}

/* If more than one output file, would need to collect them in channel */

/* Assess reads with nanoplot */

process nanoplot1 {
    publishDir "${params.outdir}/nanoplot1", mode: 'copy'

    input:
    file fastq from ch_fastq_nanoplot

    output:
    file "nanoplot1/*"
    file "num_reads_after_porechop.txt" into ch3
    file "num_bases_after_porechop.txt" into ch4

    script:
    """
    NanoPlot --fastq $fastq -o nanoplot1

    #print line 6: number of reads
    numreads=\$(echo \$(sed -n 6p nanoplot1/NanoStats.txt))
    echo After adapter chop: \$numreads > num_reads_after_porechop.txt

    #print line 8: number of bases
    numbases=\$(echo \$(sed -n 8p nanoplot1/NanoStats.txt))
    echo After adapter chop: \$numbases > num_bases_after_porechop.txt
    """
}

/*  Filter poor quality and short reads */

process nanofilt {
    publishDir "${params.outdir}/nanofilt", mode: 'copy'

    input:
    file fastq from ch_fastq_nanofilt

    output:
    file 'filtered.fastq' into ch_fastq_filtered

    script:
    """
    NanoFilt ${params.nanofilt_args} < $fastq > filtered.fastq
    """
    //enhancement: report if this process was too strict
    //and all reads were filtered out
}

/* Assess reads again with nanoplot */

process nanoplot2 {
    publishDir "${params.outdir}/nanoplot2", mode: 'copy'

    input:
    file fastq from ch_fastq_filtered

    output:
    file "nanoplot2/*"
    file "num_reads_after_filter.txt" into ch5
    file "num_bases_after_filter.txt" into ch6

    script:
    """
    NanoPlot --fastq $fastq -o nanoplot2

    #print line 6: number of reads
    numreads=\$(echo \$(sed -n 6p nanoplot2/NanoStats.txt))
    echo After filtering: \$numreads > num_reads_after_filter.txt

    #print line 8: number of bases
    numbases=\$(echo \$(sed -n 8p nanoplot2/NanoStats.txt))
    echo After filtering: \$numbases > num_bases_after_filter.txt
    """
//if [[\$numreads -lt 1]] ; then echo WARNING: THERE ARE NO READS LEFT AFTER FILTERING

}


process readsummary {
    echo true

    publishDir "${params.outdir}/read_summary", mode: 'copy'

    input:
    file a from ch1
    file b from ch2
    file c from ch3
    file d from ch4
    file e from ch5
    file f from ch6

    output:
    file "read_summary.txt"


    script:
    """
    cat $a $c $e $b $d $f | column -t -s: > read_summary.txt
    """

}





/*
========================================================================================
                         All the other parts of the script
========================================================================================
*/


def helpMessage() {
    log.info nfcoreHeader()
    log.info"""

    Usage:

    nextflow run nf-core/porepatrol --reads "path to fastq files"

    Mandatory arguments:
      --reads                       Path to input fastq data (must be surrounded with quotes)

    Options:
      -profile                      Configuration profile to use. Can use multiple (comma separated)
      --porechop_args               Additional arguments for porechop
      --nanofilt_args               Changed or extra arguments for nanofilt
      --outdir                      The output directory where the results will be saved
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    AWSBatch options:
      --awsqueue                    The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion                   The AWS Region for your AWS Batch job to run on
    """.stripIndent()
}


// Show help message
if (params.help){
    helpMessage()
    exit 0
}


// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


if( workflow.profile == 'awsbatch') {
  // AWSBatch sanity checking
  if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
  // Check outdir paths to be S3 buckets if running on AWSBatch
  // related: https://github.com/nextflow-io/nextflow/issues/813
  if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
  // Prevent trace files to be stored on S3 since S3 does not support rolling files.
  if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

// Stage config files
//ch_multiqc_config = Channel.fromPath(params.multiqc_config)
ch_output_docs = Channel.fromPath("$baseDir/docs/output.md")


// Header log info
log.info nfcoreHeader()
def summary = [:]
if(workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
// TODO nf-core: Report custom parameters here
summary['Reads']            = params.reads
//summary['Fasta Ref']        = params.fasta
//summary['Data Type']        = params.singleEnd ? 'Single-End' : 'Paired-End'
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if(workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName
if(workflow.profile == 'awsbatch'){
   summary['AWS Region']    = params.awsregion
   summary['AWS Queue']     = params.awsqueue
}
summary['Config Profile'] = workflow.profile
if(params.config_profile_description) summary['Config Description'] = params.config_profile_description
if(params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if(params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if(params.email) {
  summary['E-mail Address']  = params.email

}
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "\033[2m----------------------------------------------------\033[0m"

// Check the hostnames against configured profiles
checkHostname()

def create_workflow_summary(summary) {
    def yaml_file = workDir.resolve('workflow_summary_mqc.yaml')
    yaml_file.text  = """
    id: 'nf-core-porepatrol-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nf-core/porepatrol Workflow Summary'
    section_href: 'https://github.com/nf-core/porepatrol'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
${summary.collect { k,v -> "            <dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }.join("\n")}
        </dl>
    """.stripIndent()

   return yaml_file
}

/* Parse software version numbers */

process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy',
    saveAs: {filename ->
        if (filename.indexOf(".csv") > 0) filename
        else null
    }

    output:
    file 'software_versions_mqc.yaml' into software_versions_yaml
    file "software_versions.csv"

    script:
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    NanoPlot --version > v_nanoplot.txt
    porechop --version > v_porechop.txt
    NanoFilt --version > v_nanofilt.txt
    scrape_software_versions.py &> software_versions_mqc.yaml
    """
}


/* Output Description HTML */

process output_documentation {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    file output_docs from ch_output_docs

    output:
    file "results_description.html"

    script:
    """
    markdown_to_html.r $output_docs results_description.html
    """
}

/*
 * Completion e-mail notification
 */

workflow.onComplete {
    echo true
    // Set up the e-mail variables
    def subject = "[nf-core/porepatrol] Successful: $workflow.runName"
    if(!workflow.success){
      subject = "[nf-core/porepatrol] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if(workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if(workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if(workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    if(workflow.container) email_fields['summary']['Docker image'] = workflow.container
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: params.email, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (params.email) {
        try {
          if( params.plaintext_email ){ throw GroovyException('Send plaintext e-mail, not HTML') }
          // Try to send HTML e-mail using sendmail
          [ 'sendmail', '-t' ].execute() << sendmail_html
          log.info "[nf-core/porepatrol] Sent summary e-mail to $params.email (sendmail)"
        } catch (all) {
          // Catch failures and try with plaintext
          [ 'mail', '-s', subject, params.email ].execute() << email_txt
          log.info "[nf-core/porepatrol] Sent summary e-mail to $params.email (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File( "${params.outdir}/pipeline_info/" )
    if( !output_d.exists() ) {
      output_d.mkdirs()
    }
    def output_hf = new File( output_d, "pipeline_report.html" )
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File( output_d, "pipeline_report.txt" )
    output_tf.withWriter { w -> w << email_txt }

    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";

    if (workflow.stats.ignoredCountFmt > 0 && workflow.success) {
      log.info "${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}"
      log.info "${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCountFmt} ${c_reset}"
      log.info "${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCountFmt} ${c_reset}"
    }

    if(workflow.success){
        log.info "${c_purple}[nf-core/porepatrol]${c_green} Pipeline completed successfully${c_reset}"
        println "stuff here"
        // def readssummary = new File("$params.outdir/read_summary.txt")
        // println "cat ${readssummary}"
        //trying to print output summary here


    } else {
        checkHostname()
        log.info "${c_purple}[nf-core/porepatrol]${c_red} Pipeline completed with errors${c_reset}"
    }

}


def nfcoreHeader(){
    // Log colors ANSI codes
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";

    return """    ${c_dim}----------------------------------------------------${c_reset}
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/porepatrol v${workflow.manifest.version}${c_reset}
    ${c_dim}----------------------------------------------------${c_reset}
    """.stripIndent()
}

def checkHostname(){
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if(params.hostnames){
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if(hostname.contains(hname) && !workflow.profile.contains(prof)){
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
