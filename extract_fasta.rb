require 'logger'
require 'set'
require_relative 'lib/gene_data_loader'
require_relative 'lib/splicing'

def load_transcripts_fold_change(input_file)
  mtor_lines = File.readlines(input_file)
  column_indices = column_indices(mtor_lines[0], {enst: 'txids', fold_change: 'pp242.TE FOLD_CHANGE'})
  mtor_lines.drop(1).each_with_object(Hash.new) do |line, transcripts_fold_change|
    enst, fold_change = *extract_columns(line, [:enst, :fold_change], column_indices)
    transcripts_fold_change[enst] = fold_change
  end
end

min_expression = -Float::INFINITY

cages_file = 'source_data/prostate%20cancer%20cell%20line%3aPC-3.CNhs11243.10439-106E7.hg19.ctss.bed'
peaks_for_tissue_file = 'source_data/peaks_for_prostate%20cancer%20cell%20line%3aPC-3.txt'
transcript_infos_file = 'source_data/ensembl_transcripts.txt'
region_length = 0
genome_folder = 'source_data/genome/hg19'
mtor_fold_changes_file = 'source_data/mTOR_modified_res.csv'

framework = GeneDataLoader.new(cages_file,
                              peaks_for_tissue_file,
                              transcript_infos_file,
                              region_length,
                              genome_folder)

transcripts_fold_change = load_transcripts_fold_change(mtor_fold_changes_file)
framework.transcript_ensts_to_load = Set.new(transcripts_fold_change.keys)

logger = Logger.new($stderr)
logger.formatter = ->(severity, datetime, progname, msg) { "#{severity}: #{msg}\n" }
framework.logger = logger
Gene.logger = logger

genes = Gene.genes_from_file('source_data/protein_coding_genes.txt', 
  {hgnc: 'HGNC ID', approved_symbol: 'Approved Symbol', entrezgene: 'Entrez Gene ID', ensembl: 'Ensembl Gene ID', ensembl_external: 'Ensembl ID(supplied by Ensembl)'}
  )
genes_by_ensg = genes.group_by{|gene| gene.ensembl_id}
genes_by_external_ensg = genes.group_by{|gene| gene.ensembl_id_external}
ensgs_by_enst = read_ensgs_by_enst('source_data/mart_export.txt')

framework.setup!


File.open('weighted_5-utr_0bp_plus_peaks_annotated.txt', 'w') do |fw|
  framework.output_all_5utr(fw) do |output_stream, enst, transcript_group, peaks_info, summary_expression, spliced_sequence, spliced_cages, utr, exons_on_utr|
      # next  unless summary_expression >= min_expression
      gene_infos = ensgs_by_enst.fetch(enst, []).map do |ensg|
        genes_by_ensg.fetch(ensg) do |ensg_id|
          genes_by_external_ensg.fetch(ensg_id, [])
        end
      end.flatten.map do |gene|
        "#{gene.approved_symbol}(HGNC:#{gene.hgnc_id})"
      end.join(',')
      fold_change = transcripts_fold_change[enst]
      output_stream.puts ">#{enst}\tGenes: #{gene_infos}\tSummary expression: #{summary_expression}\tFold change: #{fold_change}\tTranscript: #{transcript_group}\tPeaks: #{peaks_info}"
      output_stream.puts spliced_sequence
      output_stream.puts spliced_sequence.each_char.to_a.join("\t")
      output_stream.puts spliced_cages.join("\t")
  end
  # framework.output_all_5utr(nil, fw) do |output_stream, enst, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
  #   
  #   output_stream.puts ">#{enst}\t#{transcript_group}\t#{expression}"
  #   output_stream.puts ">#{spliced_cages.join("\t")}"
  #   output_stream.puts spliced_sequence
  # end
end

# File.open('weighted_5-utr-polyN-masked_1.txt', 'w') do |fw|
#   framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
#     next  unless expression >= min_expression
#     output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
#     output_stream.puts mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7, 0)
#   end
# end

# File.open('weighted_5-utr-polyN-masked_5.txt', 'w') do |fw|
#   framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
#     next  unless expression >= min_expression
#     output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
#     output_stream.puts mark_best_starts_as_poly_n(spliced_sequence, spliced_cages, 0.7, 2)
#   end
# end

# File.open('weighted_5-utr-polyN-masked_good.txt', 'w') do |fw|
  # framework.output_all_5utr(genes_to_extract, fw) do |output_stream, gene_info, transcript_group, peaks_info, expression, spliced_sequence, spliced_cages|
    # next  unless expression >= min_expression
    # output_stream.puts ">#{gene_info}\t#{transcript_group}\t#{expression}"
    # output_stream.puts mark_single_best_start_as_poly_n(spliced_sequence, spliced_cages, 5)
  # end
# end
