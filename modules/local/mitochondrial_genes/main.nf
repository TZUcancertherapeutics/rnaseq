process MITHOCONDRIAL_GENES_QUANTIFY {
    label "process_medium"

    // (Bio)conda packages have intentionally not been pinned to a specific version
    // This was to avoid the pipeline failing due to package conflicts whilst creating the environment when using -profile conda
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1e130ecd2c6e47cf1d1e8de7f0c8b6446e279444:8b03ee02d3fd4c591e25416396609e9d06cdc711-0' :
        'biocontainers/mulled-v2-1e130ecd2c6e47cf1d1e8de7f0c8b6446e279444==8b03ee02d3fd4c591e25416396609e9d06cdc711-0' }"

    input:
    path counts

    output:
    path "*.tsv"                , optional:true, emit: tsv
    path "*.log"                , optional:true, emit: log
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args  ?: ''
    def args2 = task.ext.args2 ?: ''
    def label_lower = args2.toLowerCase()
    def label_upper = args2.toUpperCase()
    prefix = task.ext.prefix ?: "mitochondrial_genes"
    """
    quantify_mitochondrial.r \\
        --count_file $counts \\
        --outdir ./ \\
        --cores $task.cpus \\
        --outprefix $prefix \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        seurat: \$(Rscript -e "library(Seurat); cat(as.character(packageVersion('Seurat')))")
    END_VERSIONS
    """

    stub:
    def args2 = task.ext.args2 ?: ''
    def label_lower = args2.toLowerCase()
    prefix = task.ext.prefix ?: "deseq2"
    """
    touch ${label_lower}.tsv
    touch R_sessionInfo.log

    cat <<-END_VERSIONS >versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        seurat: \$(Rscript -e "library(Seurat); cat(as.character(packageVersion('Seurat')))")
    END_VERSIONS
    """
}
