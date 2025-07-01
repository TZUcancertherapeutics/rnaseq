#!/usr/bin/env Rscript

################################################
## test R script to implement a new simple tool into the nf-core rnaseq pipeline
## - script to detect the number of expressed genes
## - start with counts from test set GSE255889
################################################

################################################
## temporary variables to delete when integrating in the final pipeline
################################################

#USAGE Rscript number_of_exp_genes.R results/gene_counts/rnaseq.merged.gene_counts.tsv

################################################
## LOAD LIBRARIES
## - libraries are put in a separate environment for now
################################################

.libPaths("/tzu-share/users/employees/debora/libs/R/rnaseq_pipeline_4.4.3")

library(optparse)
library(ggplot2)
library(RColorBrewer)
library(gridExtra)
library(grid)

################################################
## PARSE COMMAND-LINE PARAMETERS
################################################

option_list <- list(
  make_option(c("-i", "--count_file"    ), type="character", default=NULL    , metavar="path"   , help="Count file matrix where rows are genes and columns are samples."                        ),
  make_option(c("-f", "--count_col"     ), type="integer"  , default=3       , metavar="integer", help="First column containing sample count data."                                             ),
  make_option(c("-d", "--id_col"        ), type="integer"  , default=1       , metavar="integer", help="Column containing identifiers to be used."                                              ),
  make_option(c("-u", "--cutoff"        ), type="integer"  , default=2500    , metavar="integer", help="Cutoff to flag samples with low number of genes expressed."                             ),
  make_option(c("-r", "--sample_suffix" ), type="character", default=''      , metavar="string" , help="Suffix to remove after sample name in columns e.g. '.rmDup.bam' if 'DRUG_R1.rmDup.bam'."),
  make_option(c("-o", "--outdir"        ), type="character", default='./'    , metavar="path"   , help="Output directory."                                                                      ),
  make_option(c("-p", "--outprefix"     ), type="character", default='number_of_exp_genes', metavar="string" , help="Output prefix."                                                            ),
  make_option(c("-c", "--cores"         ), type="integer"  , default=1       , metavar="integer", help="Number of cores."                                                                       )
)

opt_parser <- OptionParser(option_list=option_list)
opt        <- parse_args(opt_parser)

if (is.null(opt$count_file)){
  print_help(opt_parser)
  stop("Please provide a counts file.", call.=FALSE)
}

################################################
## READ IN COUNTS FILE
################################################

count.table           <- read.delim(file=opt$count_file,header=TRUE, row.names=NULL)
rownames(count.table) <- count.table[,opt$id_col]
count.table           <- count.table[,opt$count_col:ncol(count.table),drop=FALSE]
colnames(count.table) <- gsub(opt$sample_suffix,"",colnames(count.table))
colnames(count.table) <- gsub(pattern='\\.$', replacement='', colnames(count.table))

################################################
## COUNT NUMBER OF EXPRESSED GENES PER SAMPLE
################################################

sample.gexp    <- colSums(count.table > 0)

# Convert to data frame for ggplot2
df             <- data.frame(
                    Sample = names(sample.gexp),
                    Count = as.numeric(sample.gexp)
)

# Add a flag for whether the sample is below the cutoff
df$BelowCutoff <- df$Count < opt$cutoff

# Subset samples below cutoff
below_df       <- df[df$BelowCutoff, c("Sample", "Count")]


################################################
## PLOT 
################################################

p <- ggplot(df, aes(x = Sample, y = Count, fill = BelowCutoff)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "red")) +
  geom_hline(yintercept = opt$cutoff, linetype = "dashed", color = "black") +
  labs(
    title = "Number of expressed genes per Sample",
    x = "Sample",
    y = "Expressed genes",
    fill = "Below Cutoff"
  ) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Create a text grob listing flagged samples
if (nrow(below_df) > 0) {
  sample_text <- paste0(below_df$Sample, ": ", below_df$Count, " genes")
  text_block <- paste(
    "Samples below cutoff:",
    paste(sample_text, collapse = "\n"),
    sep = "\n"
  )
} else {
  text_block <- "No samples below cutoff"
}

text_grob <- textGrob(
  label = text_block,
  x = 0.05, hjust = 0, gp = gpar(fontsize = 10)
)

# Combine plot and text, and save to PDF
PlotFile  <- paste(opt$outprefix,".plots.pdf",sep="")

pdf(file=PlotFile, onefile=TRUE, width=length(count.table)/10+7, height=7+0.1*length(rownames(below_df)))
grid.arrange(p, text_grob, nrow = 2, heights = c(4, 1))
dev.off()

################################################
## R SESSION INFO
################################################

RLogFile <- "R_sessionInfo.log"

sink(RLogFile)
a <- sessionInfo()
print(a)
sink()
