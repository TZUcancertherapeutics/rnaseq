process GENES_QUANTIFY {
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1e130ecd2c6e47cf1d1e8de7f0c8b6446e279444:8b03ee02d3fd4c591e25416396609e9d06cdc711-0' :
        'biocontainers/mulled-v2-1e130ecd2c6e47cf1d1e8de7f0c8b6446e279444==8b03ee02d3fd4c591e25416396609e9d06cdc711-0' }"

    input:
    path counts

    output:
    path "*.pdf"                , optional:true, emit: pdf
    path "*.log"                , optional:true, emit: log
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "num_exp_genes"

    """
    number_of_exp_genes.R \\
        --count_file $counts \\
        --outdir ./ \\
        --cores $task.cpus \\
        --outprefix $prefix \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
    END_VERSIONS
    """

        stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "num_exp_genes"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.pdf
    touch R_sessionInfo.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
    END_VERSIONS
    """
}
