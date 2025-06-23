Search genomes available in `$projectDir/workflows/rnaseq/assets/fastqscreen/fastq_screen.conf`

# How to include a new genome search (bowtie index files)

## Easy-way: use fastq_screen
`fastq_screen --get_genomes`

## Custom way:
1) download fastq file of genome
2) `bowtie2-build mu_downloaded_genome.fna genome_name`

# Genomes included
* Human
* E-coli
* saccharomyces_cerevisiae (yeast)
* mycoplasma_fermentans
* mesomycoplasma_hyorhinis
* gcf_900476065 (Mesomycoplasma hyorhinis)