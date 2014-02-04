# We don't collect peaks that have zero expression

require 'logger'
$logger = Logger.new($stderr)

require_relative 'lib/gene_data_loader'

# cages_file = 'prostate%20cancer%20cell%20line%253aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
# output_file = 'spliced_transcripts.txt'

cages_file, output_file = *ARGV
raise "You should specify file with cages for a specific tissue(*.bed) and output file" unless cages_file && output_file

framework = GeneDataLoader.new(cages_file, 'HGNC_protein_coding_22032013_entrez.txt', 'knownToLocusLink.txt', 'robust_set.freeze1.reduced.pc-3', 'knownGene.txt', 100, 'source_data/genome/hg19')

File.open(output_file, 'w') do |fw|
  framework.output_all_5utr(framework.genes_to_process, fw)
end
