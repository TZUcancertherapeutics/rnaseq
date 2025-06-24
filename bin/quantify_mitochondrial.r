#!/usr/bin/env Rscript

# USAGE Rscript mito_percent.R results/gene_counts/rnaseq.merged.gene_counts.tsv

################################################
################################################
## LOAD LIBRARIES                             ##
################################################
################################################

library(Seurat)
library(Matrix)
library(dplyr)
library(optparse)

################################################
################################################
## PARSE COMMAND-LINE PARAMETERS              ##
################################################
################################################

option_list <- list(
    make_option(c("-i", "--count_file"    ), type="character", default=NULL    , metavar="path"   , help="Count file matrix where rows are genes and columns are samples."                        ),
    make_option(c("-f", "--count_col"     ), type="integer"  , default=3       , metavar="integer", help="First column containing sample count data."                                             ),
    make_option(c("-d", "--id_col"        ), type="integer"  , default=1       , metavar="integer", help="Column containing identifiers to be used."                                              ),
    make_option(c("-r", "--sample_suffix" ), type="character", default=''      , metavar="string" , help="Suffix to remove after sample name in columns e.g. '.rmDup.bam' if 'DRUG_R1.rmDup.bam'."),
    make_option(c("-o", "--outdir"        ), type="character", default='./'    , metavar="path"   , help="Output directory."                                                                      ),
    make_option(c("-p", "--outprefix"     ), type="character", default='deseq2', metavar="string" , help="Output prefix."                                                                         ),
    make_option(c("-v", "--vst"           ), type="logical"  , default=FALSE   , metavar="boolean", help="Run vst transform instead of rlog."                                                     ),
    make_option(c("-c", "--cores"         ), type="integer"  , default=1       , metavar="integer", help="Number of cores."                                                                       )
)


opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$count_file)) {
  print_help(opt_parser)
  stop("Please provide a counts file.", call.=FALSE)
}

################################################
################################################
## READ IN COUNTS FILE                        ##
################################################
################################################

count.table <- read.delim(file=opt$count_file, header=TRUE, row.names=NULL, check.names=FALSE)
rownames(count.table) <- count.table[[opt$id_col]]
count.table <- count.table[, opt$count_col:ncol(count.table), drop=FALSE]

# Clean sample column names
colnames(count.table) <- gsub(opt$sample_suffix, "", colnames(count.table))
colnames(count.table) <- gsub(pattern='\\.$', replacement='', colnames(count.table))

# === SEURAT OBJECT ===
counts_matrix <- as.matrix(count.table)
seurat_obj <- CreateSeuratObject(counts = counts_matrix)

################################################
################################################
## QUANTIFY MITOCHONDRIAL GENES               ##
################################################
################################################
mito_genes <- grep("^MT", rownames(seurat_obj), ignore.case=TRUE, value=TRUE)

if (length(mito_genes) == 0) {
  warning("No mitochondrial genes found using regex '^MT-|^chrM'.")
  seurat_obj$percent_mito <- 0
} else {
  seurat_obj <- PercentageFeatureSet(seurat_obj, features = mito_genes, col.name = "percent_mito")
}

# === OUTPUT SUMMARY ===
mito_summary <- data.frame(
  sample = colnames(seurat_obj),
  percent_reads_mitochondrial = seurat_obj$percent_mito
)

write.table(
  mito_summary,
  file = "mitochondrial_read_percentages.tsv",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)


################################################
################################################
## R SESSION INFO                             ##
################################################
################################################

RLogFile <- "R_sessionInfo_SEURAT.log"

sink(RLogFile)
a <- sessionInfo()
print(a)
sink()

cat("✅ Output written to mitochondrial_read_percentages.tsv\n")

################################################
################################################
################################################
################################################
