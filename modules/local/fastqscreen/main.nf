process FASTQSCREEN {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.16.0--pl5321hdfd78af_0':
        'biocontainers/fastq-screen:0.16.0--pl5321hdfd78af_0' }"

    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/nf-core/bwa/index/main.nf
    // nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    input:
    tuple val(meta), path(reads)

    output:
    // Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*_screen.png") , emit: png
    tuple val(meta), path("*_screen.html"), emit: html
    tuple val(meta), path("*_screen.txt") , emit: txt
    // List additional required output channels/values here
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    def old_new_pairs = reads instanceof Path || reads.size() == 1 ? [[ reads, "${prefix}.${reads.extension}" ]] : reads.withIndex().collect { entry, index -> [ entry, "${prefix}_${index + 1}.${entry.extension}" ] }
    def rename_to     = old_new_pairs*.join(' ').join(' ')
    def renamed_files = old_new_pairs.collect{ _old_name, new_name -> new_name }.join(' ')

    """
    printf "%s %s\\n" ${rename_to} | while read old_name new_name; do
        [ -f "\${new_name}" ] || ln -s \$old_name \$new_name
    done
    
    fastq_screen \\
        --aligner bowtie2 \\
        --conf /tzu-share/resources/fastq_screen/fastq_screen.conf \\
        ${args} \\
        --threads ${task.cpus} \\
        ${renamed_files}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: \$( fastq_screen --version | sed 's/.*v//' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TA stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}_screen.html
    touch ${prefix}_screen.txt
    touch ${prefix}_screen.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: \$( fastq_screen --version | sed 's/.*v//' )
    END_VERSIONS
    """
}
