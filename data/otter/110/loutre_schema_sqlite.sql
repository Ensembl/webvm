BEGIN TRANSACTION;

CREATE TABLE assembly (
  asm_seq_region_id INT(10) NOT NULL,
  cmp_seq_region_id INT(10) NOT NULL,
  asm_start INT(10) NOT NULL,
  asm_end INT(10) NOT NULL,
  cmp_start INT(10) NOT NULL,
  cmp_end INT(10) NOT NULL,
  ori TINYINT(4) NOT NULL
);

CREATE INDEX cmp_seq_region_idx ON assembly (cmp_seq_region_id);

CREATE INDEX asm_seq_region_idx ON assembly (asm_seq_region_id, asm_start);

CREATE UNIQUE INDEX all_idx ON assembly (asm_seq_region_id, cmp_seq_region_id, asm_start, asm_end, cmp_start, cmp_end, ori);

CREATE TABLE assembly_exception (
  assembly_exception_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  exc_type VARCHAR(11) NOT NULL,
  exc_seq_region_id INT(10) NOT NULL,
  exc_seq_region_start INT(10) NOT NULL,
  exc_seq_region_end INT(10) NOT NULL,
  ori int(11) NOT NULL
);

CREATE INDEX sr_idx ON assembly_exception (seq_region_id, seq_region_start);

CREATE INDEX ex_idx ON assembly_exception (exc_seq_region_id, exc_seq_region_start);

CREATE TABLE coord_system (
  coord_system_id INTEGER PRIMARY KEY NOT NULL,
  species_id INT(10) NOT NULL DEFAULT 1,
  name VARCHAR(40) NOT NULL,
  version VARCHAR(255) DEFAULT NULL,
  rank int(11) NOT NULL,
  attrib VARCHAR(15)
);

CREATE INDEX species_idx ON coord_system (species_id);

CREATE UNIQUE INDEX rank_idx ON coord_system (rank, species_id);

CREATE UNIQUE INDEX name_idx ON coord_system (name, version, species_id);

CREATE TABLE data_file (
  data_file_id INTEGER PRIMARY KEY NOT NULL,
  coord_system_id INT(10) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  name VARCHAR(100) NOT NULL,
  version_lock TINYINT(1) NOT NULL DEFAULT 0,
  absolute TINYINT(1) NOT NULL DEFAULT 0,
  url TEXT(65535),
  file_type VARCHAR(6)
);

CREATE INDEX df_name_idx ON data_file (name);

CREATE INDEX df_analysis_idx ON data_file (analysis_id);

CREATE UNIQUE INDEX df_unq_idx ON data_file (coord_system_id, analysis_id, name, file_type);

CREATE TABLE dna (
  seq_region_id INTEGER PRIMARY KEY NOT NULL,
  sequence LONGTEXT(4294967295) NOT NULL
);

CREATE TABLE genome_statistics (
  genome_statistics_id INTEGER PRIMARY KEY NOT NULL,
  statistic VARCHAR(128) NOT NULL,
  value BIGINT(11) NOT NULL DEFAULT 0,
  species_id int(10) DEFAULT 1,
  attrib_type_id INT(10) DEFAULT NULL,
  timestamp DATETIME DEFAULT NULL
);

CREATE UNIQUE INDEX stats_uniq ON genome_statistics (statistic, attrib_type_id, species_id);

CREATE TABLE karyotype (
  karyotype_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  band VARCHAR(40) DEFAULT NULL,
  stain VARCHAR(40) DEFAULT NULL
);

CREATE INDEX region_band_idx ON karyotype (seq_region_id, band);

CREATE TABLE meta (
  meta_id INTEGER PRIMARY KEY NOT NULL,
  species_id int(10) DEFAULT 1,
  meta_key VARCHAR(40) NOT NULL,
  meta_value VARCHAR(255) NOT NULL
);

CREATE INDEX species_value_idx ON meta (species_id, meta_value);

CREATE UNIQUE INDEX species_key_value_idx ON meta (species_id, meta_key, meta_value);

CREATE TABLE meta_coord (
  table_name VARCHAR(40) NOT NULL,
  coord_system_id INT(10) NOT NULL,
  max_length int(11)
);

CREATE UNIQUE INDEX cs_table_name_idx ON meta_coord (coord_system_id, table_name);

CREATE TABLE seq_region (
  seq_region_id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  coord_system_id INT(10) NOT NULL,
  length INT(10) NOT NULL
);

CREATE INDEX cs_idx ON seq_region (coord_system_id);

CREATE UNIQUE INDEX name_cs_idx ON seq_region (name, coord_system_id);

CREATE TABLE seq_region_synonym (
  seq_region_synonym_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  synonym VARCHAR(250) NOT NULL,
  external_db_id int(10)
);

CREATE INDEX seq_region_idx ON seq_region_synonym (seq_region_id);

CREATE UNIQUE INDEX syn_idx ON seq_region_synonym (synonym, seq_region_id);

CREATE TABLE seq_region_attrib (
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx ON seq_region_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx ON seq_region_attrib (value);

CREATE INDEX seq_region_idx02 ON seq_region_attrib (seq_region_id);

CREATE UNIQUE INDEX region_attribx ON seq_region_attrib (seq_region_id, attrib_type_id, value);

CREATE TABLE alt_allele (
  alt_allele_id INTEGER PRIMARY KEY NOT NULL,
  alt_allele_group_id int(10) NOT NULL,
  gene_id int(10) NOT NULL
);

CREATE INDEX alt_allele_idx ON alt_allele (gene_id, alt_allele_group_id);

CREATE UNIQUE INDEX gene_idx ON alt_allele (gene_id);

CREATE TABLE alt_allele_attrib (
  alt_allele_id int(10),
  attrib VARCHAR(35)
);

CREATE INDEX aa_idx ON alt_allele_attrib (alt_allele_id, attrib);

CREATE TABLE alt_allele_group (
  alt_allele_group_id INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE analysis (
  analysis_id INTEGER PRIMARY KEY NOT NULL,
  created datetime DEFAULT NULL,
  logic_name VARCHAR(128) NOT NULL,
  db VARCHAR(120),
  db_version VARCHAR(40),
  db_file VARCHAR(120),
  program VARCHAR(80),
  program_version VARCHAR(40),
  program_file VARCHAR(80),
  parameters TEXT(65535),
  module VARCHAR(80),
  module_version VARCHAR(40),
  gff_source VARCHAR(40),
  gff_feature VARCHAR(40)
);

CREATE UNIQUE INDEX logic_name_idx ON analysis (logic_name);

CREATE TABLE analysis_description (
  analysis_id SMALLINT(5) NOT NULL,
  description TEXT(65535),
  display_label VARCHAR(255) NOT NULL,
  displayable TINYINT(1) NOT NULL DEFAULT 1,
  web_data TEXT(65535)
);

CREATE UNIQUE INDEX analysis_idx ON analysis_description (analysis_id);

CREATE TABLE attrib_type (
  attrib_type_id INTEGER PRIMARY KEY NOT NULL,
  code VARCHAR(20) NOT NULL DEFAULT '',
  name VARCHAR(255) NOT NULL DEFAULT '',
  description TEXT(65535)
);

CREATE UNIQUE INDEX code_idx ON attrib_type (code);

CREATE TABLE dna_align_feature (
  dna_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(1) NOT NULL,
  hit_start int(11) NOT NULL,
  hit_end int(11) NOT NULL,
  hit_strand TINYINT(1) NOT NULL,
  hit_name VARCHAR(40) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  score DOUBLE,
  evalue DOUBLE,
  perc_ident FLOAT,
  cigar_line TEXT(65535),
  external_db_id int(10),
  hcoverage DOUBLE,
  align_type VARCHAR(7) DEFAULT 'ensembl'
);

CREATE INDEX seq_region_idx03 ON dna_align_feature (seq_region_id, analysis_id, seq_region_start, score);

CREATE INDEX seq_region_idx_2 ON dna_align_feature (seq_region_id, seq_region_start);

CREATE INDEX hit_idx ON dna_align_feature (hit_name);

CREATE INDEX analysis_idx02 ON dna_align_feature (analysis_id);

CREATE INDEX external_db_idx ON dna_align_feature (external_db_id);

CREATE TABLE dna_align_feature_attrib (
  dna_align_feature_id INT(10) NOT NULL,
  attrib_type_id SMALLINT(5) NOT NULL,
  value TEXT(65535) NOT NULL
);

CREATE INDEX dna_align_feature_idx ON dna_align_feature_attrib (dna_align_feature_id);

CREATE INDEX type_val_idx02 ON dna_align_feature_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx02 ON dna_align_feature_attrib (value);

CREATE UNIQUE INDEX dna_align_feature_attribx ON dna_align_feature_attrib (dna_align_feature_id, attrib_type_id, value);

CREATE TABLE exon (
  exon_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  phase TINYINT(2) NOT NULL,
  end_phase TINYINT(2) NOT NULL,
  is_current TINYINT(1) NOT NULL DEFAULT 1,
  is_constitutive TINYINT(1) NOT NULL DEFAULT 0,
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX seq_region_idx04 ON exon (seq_region_id, seq_region_start);

CREATE INDEX stable_id_idx ON exon (stable_id, version);

CREATE TABLE exon_transcript (
  exon_id INT(10) NOT NULL,
  transcript_id INT(10) NOT NULL,
  rank INT(10) NOT NULL,
  PRIMARY KEY (exon_id, transcript_id, rank)
);

CREATE INDEX transcriptx ON exon_transcript (transcript_id);

CREATE INDEX exon0x2 ON exon_transcript (exon_id);

CREATE TABLE gene (
  gene_id INTEGER PRIMARY KEY NOT NULL,
  biotype VARCHAR(40) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  display_xref_id INT(10),
  source VARCHAR(40) NOT NULL,
  description TEXT(65535),
  is_current TINYINT(1) NOT NULL DEFAULT 1,
  canonical_transcript_id INT(10) NOT NULL,
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX seq_region_idx05 ON gene (seq_region_id, seq_region_start);

CREATE INDEX xref_id_index ON gene (display_xref_id);

CREATE INDEX analysis_idx03 ON gene (analysis_id);

CREATE INDEX stable_id_idx02 ON gene (stable_id, version);

CREATE INDEX canonical_transcript_id_idx ON gene (canonical_transcript_id);

CREATE TABLE gene_attrib (
  gene_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx03 ON gene_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx03 ON gene_attrib (value);

CREATE INDEX gene_idx02 ON gene_attrib (gene_id);

CREATE UNIQUE INDEX gene_attribx ON gene_attrib (gene_id, attrib_type_id, value);

CREATE TABLE protein_align_feature (
  protein_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(1) NOT NULL DEFAULT 1,
  hit_start INT(10) NOT NULL,
  hit_end INT(10) NOT NULL,
  hit_name VARCHAR(40) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  score DOUBLE,
  evalue DOUBLE,
  perc_ident FLOAT,
  cigar_line TEXT(65535),
  external_db_id int(10),
  hcoverage DOUBLE,
  align_type VARCHAR(7) DEFAULT 'ensembl'
);

CREATE INDEX seq_region_idx06 ON protein_align_feature (seq_region_id, analysis_id, seq_region_start, score);

CREATE INDEX seq_region_idx_202 ON protein_align_feature (seq_region_id, seq_region_start);

CREATE INDEX hit_idx02 ON protein_align_feature (hit_name);

CREATE INDEX analysis_idx04 ON protein_align_feature (analysis_id);

CREATE INDEX external_db_idx02 ON protein_align_feature (external_db_id);

CREATE TABLE protein_feature (
  protein_feature_id INTEGER PRIMARY KEY NOT NULL,
  translation_id INT(10) NOT NULL,
  seq_start INT(10) NOT NULL,
  seq_end INT(10) NOT NULL,
  hit_start INT(10) NOT NULL,
  hit_end INT(10) NOT NULL,
  hit_name VARCHAR(40) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  score DOUBLE,
  evalue DOUBLE,
  perc_ident FLOAT,
  external_data TEXT(65535),
  hit_description TEXT(65535),
  cigar_line TEXT(65535),
  align_type VARCHAR(9) DEFAULT NULL
);

CREATE INDEX translation_idx ON protein_feature (translation_id);

CREATE INDEX hitname_idx ON protein_feature (hit_name);

CREATE INDEX analysis_idx05 ON protein_feature (analysis_id);

CREATE UNIQUE INDEX aln_idx ON protein_feature (translation_id, hit_name, seq_start, seq_end, hit_start, hit_end, analysis_id);

CREATE TABLE supporting_feature (
  exon_id INT(10) NOT NULL DEFAULT 0,
  feature_type VARCHAR(21),
  feature_id INT(10) NOT NULL DEFAULT 0
);

CREATE INDEX feature_idx ON supporting_feature (feature_type, feature_id);

CREATE UNIQUE INDEX all_idx02 ON supporting_feature (exon_id, feature_type, feature_id);

CREATE TABLE transcript (
  transcript_id INTEGER PRIMARY KEY NOT NULL,
  gene_id INT(10),
  analysis_id SMALLINT(5) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  display_xref_id INT(10),
  source VARCHAR(40) NOT NULL DEFAULT 'ensembl',
  biotype VARCHAR(40) NOT NULL,
  description TEXT(65535),
  is_current TINYINT(1) NOT NULL DEFAULT 1,
  canonical_translation_id INT(10),
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX seq_region_idx07 ON transcript (seq_region_id, seq_region_start);

CREATE INDEX gene_index ON transcript (gene_id);

CREATE INDEX xref_id_index02 ON transcript (display_xref_id);

CREATE INDEX analysis_idx06 ON transcript (analysis_id);

CREATE INDEX stable_id_idx03 ON transcript (stable_id, version);

CREATE UNIQUE INDEX canonical_translation_idx ON transcript (canonical_translation_id);

CREATE TABLE transcript_attrib (
  transcript_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx04 ON transcript_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx04 ON transcript_attrib (value);

CREATE INDEX transcript_idx ON transcript_attrib (transcript_id);

CREATE UNIQUE INDEX transcript_attribx ON transcript_attrib (transcript_id, attrib_type_id, value);

CREATE TABLE transcript_supporting_feature (
  transcript_id INT(10) NOT NULL DEFAULT 0,
  feature_type VARCHAR(21),
  feature_id INT(10) NOT NULL DEFAULT 0
);

CREATE INDEX feature_idx02 ON transcript_supporting_feature (feature_type, feature_id);

CREATE UNIQUE INDEX all_idx03 ON transcript_supporting_feature (transcript_id, feature_type, feature_id);

CREATE TABLE translation (
  translation_id INTEGER PRIMARY KEY NOT NULL,
  transcript_id INT(10) NOT NULL,
  seq_start INT(10) NOT NULL,
  -- relative to exon start
  start_exon_id INT(10) NOT NULL,
  seq_end INT(10) NOT NULL,
  -- relative to exon start
  end_exon_id INT(10) NOT NULL,
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX transcript_idx02 ON translation (transcript_id);

CREATE INDEX stable_id_idx04 ON translation (stable_id, version);

CREATE TABLE translation_attrib (
  translation_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx05 ON translation_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx05 ON translation_attrib (value);

CREATE INDEX translation_idx02 ON translation_attrib (translation_id);

CREATE UNIQUE INDEX translation_attribx ON translation_attrib (translation_id, attrib_type_id, value);

CREATE TABLE density_feature (
  density_feature_id INTEGER PRIMARY KEY NOT NULL,
  density_type_id INT(10) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  density_value FLOAT NOT NULL
);

CREATE INDEX seq_region_idx08 ON density_feature (density_type_id, seq_region_id, seq_region_start);

CREATE INDEX seq_region_id_idx ON density_feature (seq_region_id);

CREATE TABLE density_type (
  density_type_id INTEGER PRIMARY KEY NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  block_size int(11) NOT NULL,
  region_features int(11) NOT NULL,
  value_type VARCHAR(5) NOT NULL
);

CREATE UNIQUE INDEX analysis_idx07 ON density_type (analysis_id, block_size, region_features);

CREATE TABLE ditag (
  ditag_id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(30) NOT NULL,
  type VARCHAR(30) NOT NULL,
  tag_count smallint(6) NOT NULL DEFAULT 1,
  sequence TINYTEXT(255) NOT NULL
);

CREATE TABLE ditag_feature (
  ditag_feature_id INTEGER PRIMARY KEY NOT NULL,
  ditag_id INT(10) NOT NULL DEFAULT 0,
  ditag_pair_id INT(10) NOT NULL DEFAULT 0,
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  seq_region_start INT(10) NOT NULL DEFAULT 0,
  seq_region_end INT(10) NOT NULL DEFAULT 0,
  seq_region_strand TINYINT(1) NOT NULL DEFAULT 0,
  analysis_id SMALLINT(5) NOT NULL DEFAULT 0,
  hit_start INT(10) NOT NULL DEFAULT 0,
  hit_end INT(10) NOT NULL DEFAULT 0,
  hit_strand TINYINT(1) NOT NULL DEFAULT 0,
  cigar_line TINYTEXT(255) NOT NULL,
  ditag_side VARCHAR(1) NOT NULL
);

CREATE INDEX ditag_idx ON ditag_feature (ditag_id);

CREATE INDEX ditag_pair_idx ON ditag_feature (ditag_pair_id);

CREATE INDEX seq_region_idx09 ON ditag_feature (seq_region_id, seq_region_start, seq_region_end);

CREATE TABLE intron_supporting_evidence (
  intron_supporting_evidence_id INTEGER PRIMARY KEY NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  hit_name VARCHAR(100) NOT NULL,
  score DECIMAL(10,3),
  score_type VARCHAR(5) DEFAULT 'NONE',
  is_splice_canonical TINYINT(1) NOT NULL DEFAULT 0
);

CREATE INDEX seq_region_idx10 ON intron_supporting_evidence (seq_region_id, seq_region_start);

CREATE UNIQUE INDEX intron_supporting_evidence_idx ON intron_supporting_evidence (analysis_id, seq_region_id, seq_region_start, seq_region_end, seq_region_strand, hit_name);

CREATE TABLE map (
  map_id INTEGER PRIMARY KEY NOT NULL,
  map_name VARCHAR(30) NOT NULL
);

CREATE TABLE marker (
  marker_id INTEGER PRIMARY KEY NOT NULL,
  display_marker_synonym_id INT(10),
  left_primer VARCHAR(100) NOT NULL,
  right_primer VARCHAR(100) NOT NULL,
  min_primer_dist INT(10) NOT NULL,
  max_primer_dist INT(10) NOT NULL,
  priority int(11),
  type VARCHAR(14)
);

CREATE INDEX marker_idx ON marker (marker_id, priority);

CREATE INDEX display_idx ON marker (display_marker_synonym_id);

CREATE TABLE marker_feature (
  marker_feature_id INTEGER PRIMARY KEY NOT NULL,
  marker_id INT(10) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  map_weight INT(10)
);

CREATE INDEX seq_region_idx11 ON marker_feature (seq_region_id, seq_region_start);

CREATE INDEX analysis_idx08 ON marker_feature (analysis_id);

CREATE TABLE marker_map_location (
  marker_id INT(10) NOT NULL,
  map_id INT(10) NOT NULL,
  chromosome_name VARCHAR(15) NOT NULL,
  marker_synonym_id INT(10) NOT NULL,
  position VARCHAR(15) NOT NULL,
  lod_score DOUBLE,
  PRIMARY KEY (marker_id, map_id)
);

CREATE INDEX map_idx ON marker_map_location (map_id, chromosome_name, position);

CREATE TABLE marker_synonym (
  marker_synonym_id INTEGER PRIMARY KEY NOT NULL,
  marker_id INT(10) NOT NULL,
  source VARCHAR(20),
  name VARCHAR(50)
);

CREATE INDEX marker_synonym_idx ON marker_synonym (marker_synonym_id, name);

CREATE INDEX marker_idx02 ON marker_synonym (marker_id);

CREATE TABLE misc_attrib (
  misc_feature_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx06 ON misc_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx06 ON misc_attrib (value);

CREATE INDEX misc_feature_idx ON misc_attrib (misc_feature_id);

CREATE UNIQUE INDEX misc_attribx ON misc_attrib (misc_feature_id, attrib_type_id, value);

CREATE TABLE misc_feature (
  misc_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  seq_region_start INT(10) NOT NULL DEFAULT 0,
  seq_region_end INT(10) NOT NULL DEFAULT 0,
  seq_region_strand TINYINT(4) NOT NULL DEFAULT 0
);

CREATE INDEX seq_region_idx12 ON misc_feature (seq_region_id, seq_region_start);

CREATE TABLE misc_feature_misc_set (
  misc_feature_id INT(10) NOT NULL DEFAULT 0,
  misc_set_id SMALLINT(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (misc_feature_id, misc_set_id)
);

CREATE INDEX reverse_idx ON misc_feature_misc_set (misc_set_id, misc_feature_id);

CREATE TABLE misc_set (
  misc_set_id INTEGER PRIMARY KEY NOT NULL,
  code VARCHAR(25) NOT NULL DEFAULT '',
  name VARCHAR(255) NOT NULL DEFAULT '',
  description TEXT(65535) NOT NULL,
  max_length int(10) NOT NULL
);

CREATE UNIQUE INDEX code_idx02 ON misc_set (code);

CREATE TABLE prediction_exon (
  prediction_exon_id INTEGER PRIMARY KEY NOT NULL,
  prediction_transcript_id INT(10) NOT NULL,
  exon_rank SMALLINT(5) NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(4) NOT NULL,
  start_phase TINYINT(4) NOT NULL,
  score DOUBLE,
  p_value DOUBLE
);

CREATE INDEX transcript_idx03 ON prediction_exon (prediction_transcript_id);

CREATE INDEX seq_region_idx13 ON prediction_exon (seq_region_id, seq_region_start);

CREATE TABLE prediction_transcript (
  prediction_transcript_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(4) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  display_label VARCHAR(255)
);

CREATE INDEX seq_region_idx14 ON prediction_transcript (seq_region_id, seq_region_start);

CREATE INDEX analysis_idx09 ON prediction_transcript (analysis_id);

CREATE TABLE repeat_consensus (
  repeat_consensus_id INTEGER PRIMARY KEY NOT NULL,
  repeat_name VARCHAR(255) NOT NULL,
  repeat_class VARCHAR(100) NOT NULL,
  repeat_type VARCHAR(40) NOT NULL,
  repeat_consensus TEXT(65535)
);

CREATE INDEX namex ON repeat_consensus (repeat_name);

CREATE INDEX classx ON repeat_consensus (repeat_class);

CREATE INDEX consensusx ON repeat_consensus (repeat_consensus);

CREATE INDEX typex ON repeat_consensus (repeat_type);

CREATE TABLE repeat_feature (
  repeat_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(1) NOT NULL DEFAULT 1,
  repeat_start INT(10) NOT NULL,
  repeat_end INT(10) NOT NULL,
  repeat_consensus_id INT(10) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  score DOUBLE
);

CREATE INDEX seq_region_idx15 ON repeat_feature (seq_region_id, seq_region_start);

CREATE INDEX repeat_idx ON repeat_feature (repeat_consensus_id);

CREATE INDEX analysis_idx10 ON repeat_feature (analysis_id);

CREATE TABLE simple_feature (
  simple_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(1) NOT NULL,
  display_label VARCHAR(255) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  score DOUBLE
);

CREATE INDEX seq_region_idx16 ON simple_feature (seq_region_id, seq_region_start);

CREATE INDEX analysis_idx11 ON simple_feature (analysis_id);

CREATE INDEX hit_idx03 ON simple_feature (display_label);

CREATE TABLE transcript_intron_supporting_evidence (
  transcript_id INT(10) NOT NULL,
  intron_supporting_evidence_id INT(10) NOT NULL,
  previous_exon_id INT(10) NOT NULL,
  next_exon_id INT(10) NOT NULL,
  PRIMARY KEY (intron_supporting_evidence_id, transcript_id)
);

CREATE INDEX transcript_idx04 ON transcript_intron_supporting_evidence (transcript_id);

CREATE TABLE gene_archive (
  gene_stable_id VARCHAR(128) NOT NULL,
  gene_version SMALLINT(6) NOT NULL DEFAULT 1,
  transcript_stable_id VARCHAR(128) NOT NULL,
  transcript_version SMALLINT(6) NOT NULL DEFAULT 1,
  translation_stable_id VARCHAR(128),
  translation_version SMALLINT(6) NOT NULL DEFAULT 1,
  peptide_archive_id INT(10),
  mapping_session_id INT(10) NOT NULL
);

CREATE INDEX gene_idx03 ON gene_archive (gene_stable_id, gene_version);

CREATE INDEX transcript_idx05 ON gene_archive (transcript_stable_id, transcript_version);

CREATE INDEX translation_idx03 ON gene_archive (translation_stable_id, translation_version);

CREATE INDEX peptide_archive_id_idx ON gene_archive (peptide_archive_id);

CREATE TABLE mapping_session (
  mapping_session_id INTEGER PRIMARY KEY NOT NULL,
  old_db_name VARCHAR(80) NOT NULL DEFAULT '',
  new_db_name VARCHAR(80) NOT NULL DEFAULT '',
  old_release VARCHAR(5) NOT NULL DEFAULT '',
  new_release VARCHAR(5) NOT NULL DEFAULT '',
  old_assembly VARCHAR(20) NOT NULL DEFAULT '',
  new_assembly VARCHAR(20) NOT NULL DEFAULT '',
  created DATETIME NOT NULL
);

CREATE TABLE peptide_archive (
  peptide_archive_id INTEGER PRIMARY KEY NOT NULL,
  md5_checksum VARCHAR(32),
  peptide_seq MEDIUMTEXT(16777215) NOT NULL
);

CREATE INDEX checksumx ON peptide_archive (md5_checksum);

CREATE TABLE mapping_set (
  mapping_set_id INTEGER PRIMARY KEY NOT NULL,
  internal_schema_build VARCHAR(20) NOT NULL,
  external_schema_build VARCHAR(20) NOT NULL
);

CREATE UNIQUE INDEX mapping_idx ON mapping_set (internal_schema_build, external_schema_build);

CREATE TABLE stable_id_event (
  old_stable_id VARCHAR(128),
  old_version SMALLINT(6),
  new_stable_id VARCHAR(128),
  new_version SMALLINT(6),
  mapping_session_id INT(10) NOT NULL DEFAULT 0,
  type VARCHAR(11) NOT NULL,
  score FLOAT NOT NULL DEFAULT 0
);

CREATE INDEX new_idx ON stable_id_event (new_stable_id);

CREATE INDEX old_idx ON stable_id_event (old_stable_id);

CREATE UNIQUE INDEX uni_idx ON stable_id_event (mapping_session_id, old_stable_id, new_stable_id, type);

CREATE TABLE seq_region_mapping (
  external_seq_region_id INT(10) NOT NULL,
  internal_seq_region_id INT(10) NOT NULL,
  mapping_set_id INT(10) NOT NULL
);

CREATE INDEX mapping_set_idx ON seq_region_mapping (mapping_set_id);

CREATE TABLE associated_group (
  associated_group_id INTEGER PRIMARY KEY NOT NULL,
  description VARCHAR(128) DEFAULT NULL
);

CREATE TABLE associated_xref (
  associated_xref_id INTEGER PRIMARY KEY NOT NULL,
  object_xref_id INT(10) NOT NULL DEFAULT 0,
  xref_id INT(10) NOT NULL DEFAULT 0,
  source_xref_id INT(10) DEFAULT NULL,
  condition_type VARCHAR(128) DEFAULT NULL,
  associated_group_id INT(10) DEFAULT NULL,
  rank INT(10) DEFAULT 0
);

CREATE INDEX associated_source_idx ON associated_xref (source_xref_id);

CREATE INDEX associated_object_idx ON associated_xref (object_xref_id);

CREATE INDEX associated_idx ON associated_xref (xref_id);

CREATE INDEX associated_group_idx ON associated_xref (associated_group_id);

CREATE UNIQUE INDEX object_associated_source_type_idx ON associated_xref (object_xref_id, xref_id, source_xref_id, condition_type, associated_group_id);

CREATE TABLE dependent_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  master_xref_id INT(10) NOT NULL,
  dependent_xref_id INT(10) NOT NULL
);

CREATE INDEX dependentx ON dependent_xref (dependent_xref_id);

CREATE INDEX master_idx ON dependent_xref (master_xref_id);

CREATE TABLE external_db (
  external_db_id INTEGER PRIMARY KEY NOT NULL,
  db_name VARCHAR(100) NOT NULL,
  db_release VARCHAR(255),
  status VARCHAR(9) NOT NULL,
  priority int(11) NOT NULL,
  db_display_name VARCHAR(255),
  type VARCHAR(18),
  secondary_db_name VARCHAR(255) DEFAULT NULL,
  secondary_db_table VARCHAR(255) DEFAULT NULL,
  description TEXT(65535)
);

CREATE UNIQUE INDEX db_name_db_release_idx ON external_db (db_name, db_release);

CREATE TABLE biotype (
  biotype_id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(64) NOT NULL,
  object_type VARCHAR(10) NOT NULL DEFAULT 'gene',
  db_type varchar(19) NOT NULL DEFAULT 'core',
  attrib_type_id int(11) DEFAULT NULL,
  description TEXT(65535),
  biotype_group VARCHAR(10) DEFAULT NULL,
  so_acc VARCHAR(64),
  so_term VARCHAR(1023)
);

CREATE UNIQUE INDEX name_type_idx ON biotype (name, object_type);

CREATE TABLE external_synonym (
  xref_id INT(10) NOT NULL,
  synonym VARCHAR(100) NOT NULL,
  PRIMARY KEY (xref_id, synonym)
);

CREATE INDEX name_index ON external_synonym (synonym);

CREATE TABLE identity_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  xref_identity INT(5),
  ensembl_identity INT(5),
  xref_start int(11),
  xref_end int(11),
  ensembl_start int(11),
  ensembl_end int(11),
  cigar_line TEXT(65535),
  score DOUBLE,
  evalue DOUBLE
);

CREATE TABLE interpro (
  interpro_ac VARCHAR(40) NOT NULL,
  id VARCHAR(40) NOT NULL
);

CREATE INDEX id_idx ON interpro (id);

CREATE UNIQUE INDEX accession_idx ON interpro (interpro_ac, id);

CREATE TABLE object_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  ensembl_id INT(10) NOT NULL,
  ensembl_object_type VARCHAR(16) NOT NULL,
  xref_id INT(10) NOT NULL,
  linkage_annotation VARCHAR(255) DEFAULT NULL,
  analysis_id SMALLINT(5)
);

CREATE INDEX ensembl_idx ON object_xref (ensembl_object_type, ensembl_id);

CREATE INDEX analysis_idx12 ON object_xref (analysis_id);

CREATE UNIQUE INDEX xref_idx ON object_xref (xref_id, ensembl_object_type, ensembl_id, analysis_id);

CREATE TABLE ontology_xref (
  object_xref_id INT(10) NOT NULL DEFAULT 0,
  source_xref_id INT(10) DEFAULT NULL,
  linkage_type VARCHAR(3) DEFAULT NULL
);

CREATE INDEX source_idx ON ontology_xref (source_xref_id);

CREATE INDEX object_idx ON ontology_xref (object_xref_id);

CREATE UNIQUE INDEX object_source_type_idx ON ontology_xref (object_xref_id, source_xref_id, linkage_type);

CREATE TABLE unmapped_object (
  unmapped_object_id INTEGER PRIMARY KEY NOT NULL,
  type VARCHAR(6) NOT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  external_db_id int(10),
  identifier VARCHAR(255) NOT NULL,
  unmapped_reason_id INT(10) NOT NULL,
  query_score DOUBLE,
  target_score DOUBLE,
  ensembl_id INT(10) DEFAULT 0,
  ensembl_object_type VARCHAR(11) DEFAULT 'RawContig',
  parent VARCHAR(255) DEFAULT NULL
);

CREATE INDEX id_idx02 ON unmapped_object (identifier);

CREATE INDEX anal_exdb_idx ON unmapped_object (analysis_id, external_db_id);

CREATE INDEX ext_db_identifier_idx ON unmapped_object (external_db_id, identifier);

CREATE UNIQUE INDEX unique_unmapped_obj_idx ON unmapped_object (ensembl_id, ensembl_object_type, identifier, unmapped_reason_id, parent, external_db_id);

CREATE TABLE unmapped_reason (
  unmapped_reason_id INTEGER PRIMARY KEY NOT NULL,
  summary_description VARCHAR(255),
  full_description VARCHAR(255)
);

CREATE TABLE xref (
  xref_id INTEGER PRIMARY KEY NOT NULL,
  external_db_id int(10) NOT NULL,
  dbprimary_acc VARCHAR(512) NOT NULL,
  display_label VARCHAR(512) NOT NULL,
  version VARCHAR(10) DEFAULT NULL,
  description TEXT(65535),
  info_type VARCHAR(18) NOT NULL DEFAULT 'NONE',
  info_text VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE INDEX display_index ON xref (display_label);

CREATE INDEX info_type_idx ON xref (info_type);

CREATE UNIQUE INDEX id_index ON xref (dbprimary_acc, external_db_id, info_type, info_text, version);

CREATE TABLE operon (
  operon_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  display_label VARCHAR(255) DEFAULT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX seq_region_idx17 ON operon (seq_region_id, seq_region_start);

CREATE INDEX name_idx02 ON operon (display_label);

CREATE INDEX stable_id_idx05 ON operon (stable_id, version);

CREATE TABLE operon_transcript (
  operon_transcript_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL,
  seq_region_start INT(10) NOT NULL,
  seq_region_end INT(10) NOT NULL,
  seq_region_strand TINYINT(2) NOT NULL,
  operon_id INT(10) NOT NULL,
  display_label VARCHAR(255) DEFAULT NULL,
  analysis_id SMALLINT(5) NOT NULL,
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX operon_idx ON operon_transcript (operon_id);

CREATE INDEX seq_region_idx18 ON operon_transcript (seq_region_id, seq_region_start);

CREATE INDEX stable_id_idx06 ON operon_transcript (stable_id, version);

CREATE TABLE operon_transcript_gene (
  operon_transcript_id INT(10),
  gene_id INT(10)
);

CREATE INDEX operon_transcript_gene_idx ON operon_transcript_gene (operon_transcript_id, gene_id);

CREATE TABLE rnaproduct (
  rnaproduct_id INTEGER PRIMARY KEY NOT NULL,
  rnaproduct_type_id SMALLINT(5) NOT NULL,
  transcript_id INT(10) NOT NULL,
  seq_start INT(10) NOT NULL,
  -- relative to transcript start
  start_exon_id INT(10),
  seq_end INT(10) NOT NULL,
  -- relative to transcript start
  end_exon_id INT(10),
  stable_id VARCHAR(128) DEFAULT NULL,
  version SMALLINT(5) DEFAULT NULL,
  created_date DATETIME DEFAULT NULL,
  modified_date DATETIME DEFAULT NULL
);

CREATE INDEX transcript_idx06 ON rnaproduct (transcript_id);

CREATE INDEX stable_id_idx07 ON rnaproduct (stable_id, version);

CREATE TABLE rnaproduct_attrib (
  rnaproduct_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL
);

CREATE INDEX type_val_idx07 ON rnaproduct_attrib (attrib_type_id, value);

CREATE INDEX val_only_idx07 ON rnaproduct_attrib (value);

CREATE INDEX rnaproduct_idx ON rnaproduct_attrib (rnaproduct_id);

CREATE UNIQUE INDEX rnaproduct_attribx ON rnaproduct_attrib (rnaproduct_id, attrib_type_id, value);

CREATE TABLE rnaproduct_type (
  rnaproduct_type_id INTEGER PRIMARY KEY NOT NULL,
  code VARCHAR(20) NOT NULL DEFAULT '',
  name VARCHAR(255) NOT NULL DEFAULT '',
  description TEXT(65535)
);

CREATE UNIQUE INDEX code_idx03 ON rnaproduct_type (code);

CREATE TABLE gene_stable_id_pool (
  gene_pool_id INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE gene_author (
  gene_id INTEGER PRIMARY KEY NOT NULL,
  author_id INT(10) NOT NULL DEFAULT 0,
  FOREIGN KEY (gene_id) REFERENCES gene(gene_id),
  FOREIGN KEY (author_id) REFERENCES author(author_id)
);

CREATE INDEX gene_author_idx ON gene_author (author_id);

CREATE TABLE transcript_stable_id_pool (
  transcript_pool_id INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE transcript_author (
  transcript_id INTEGER PRIMARY KEY NOT NULL DEFAULT 0,
  author_id INT(10) NOT NULL DEFAULT 0,
  FOREIGN KEY (transcript_id) REFERENCES transcript(transcript_id),
  FOREIGN KEY (author_id) REFERENCES author(author_id)
);

CREATE INDEX transcript_author_idx ON transcript_author (author_id);

CREATE TABLE evidence (
  transcript_id int(10) NOT NULL DEFAULT 0,
  name VARCHAR(40) NOT NULL DEFAULT '',
  type VARCHAR(7) NOT NULL DEFAULT 'EST',
  PRIMARY KEY (transcript_id, name, type),
  FOREIGN KEY (transcript_id) REFERENCES transcript(transcript_id)
);

CREATE TABLE translation_stable_id_pool (
  translation_pool_id INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE exon_stable_id_pool (
  exon_pool_id INTEGER PRIMARY KEY NOT NULL
);

CREATE TABLE author (
  author_id INTEGER PRIMARY KEY NOT NULL,
  author_email VARCHAR(50) NOT NULL DEFAULT '',
  author_name VARCHAR(50) NOT NULL DEFAULT '',
  group_id INT(10) NOT NULL DEFAULT 0,
  FOREIGN KEY (group_id) REFERENCES author_group(group_id)
);

CREATE UNIQUE INDEX author_idx ON author (author_name, author_email);

CREATE UNIQUE INDEX author_idx02 ON author (author_email, group_id);

CREATE TABLE author_group (
  group_id INTEGER PRIMARY KEY NOT NULL,
  group_name VARCHAR(100) NOT NULL DEFAULT '',
  group_email VARCHAR(50) DEFAULT NULL
);

CREATE UNIQUE INDEX gn_idx ON author_group (group_name);

CREATE TABLE contig_info (
  contig_info_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  author_id INT(10) NOT NULL DEFAULT 0,
  created_date DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  is_current BOOLEAN NOT NULL DEFAULT 1,
  FOREIGN KEY (seq_region_id) REFERENCES seq_region_id(seq_region),
  FOREIGN KEY (author_id) REFERENCES author(author_id)
);

CREATE TABLE contig_attrib (
  contig_info_id INT(10) NOT NULL DEFAULT 0,
  attrib_type_id SMALLINT(5) NOT NULL DEFAULT 0,
  value TEXT(65535) NOT NULL,
  FOREIGN KEY (contig_info_id) REFERENCES contig_info(contig_info_id),
  FOREIGN KEY (attrib_type_id) REFERENCES attrib_type(attrib_type_id)
);

CREATE INDEX contig_attrib_idx ON contig_attrib (contig_info_id, attrib_type_id);

CREATE TABLE assembly_tag (
  tag_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  seq_region_start INT(10) NOT NULL DEFAULT 0,
  seq_region_end INT(10) NOT NULL DEFAULT 0,
  seq_region_strand tinyint(1) NOT NULL DEFAULT 0,
  tag_type VARCHAR(15) NOT NULL DEFAULT 'Misc',
  tag_info TEXT(65535),
  FOREIGN KEY (seq_region_id) REFERENCES seq_region(seq_region_id)
);

CREATE UNIQUE INDEX assembly_tag_idx ON assembly_tag (seq_region_id, seq_region_start, seq_region_end, seq_region_strand, tag_type, tag_info);

CREATE TABLE sequence_note (
  seq_region_id INT(10) NOT NULL DEFAULT 0,
  author_id INT(10) NOT NULL DEFAULT 0,
  note_time DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  is_current VARCHAR(3) NOT NULL DEFAULT 'no',
  note TEXT(65535),
  PRIMARY KEY (seq_region_id, author_id, note_time),
  FOREIGN KEY (seq_region_id) REFERENCES seq_region(seq_region_id),
  FOREIGN KEY (author_id) REFERENCES author(author_id)
);

CREATE INDEX sequence_note_idx ON sequence_note (seq_region_id, is_current);

CREATE TABLE sequence_set_access (
  seq_region_id int(10) NOT NULL DEFAULT 0,
  author_id int(10) NOT NULL DEFAULT 0,
  access_type enum(2) NOT NULL DEFAULT 'R',
  PRIMARY KEY (seq_region_id, author_id)
);

CREATE TABLE slice_lock (
  slice_lock_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id int(10) NOT NULL,
  seq_region_start int(10) NOT NULL,
  seq_region_end int(10) NOT NULL,
  author_id int(10) NOT NULL,
  ts_begin DATETIME NOT NULL,
  ts_activity DATETIME NOT NULL,
  active VARCHAR(4) NOT NULL,
  freed VARCHAR(11) DEFAULT NULL,
  freed_author_id int(11) DEFAULT NULL,
  intent VARCHAR(100) NOT NULL,
  hostname VARCHAR(100) NOT NULL,
  otter_version VARCHAR(16) DEFAULT NULL,
  ts_free DATETIME DEFAULT NULL
);

CREATE INDEX seq_region_idx19 ON slice_lock (seq_region_id, seq_region_start);

CREATE INDEX active_author_idx ON slice_lock (active, author_id);

CREATE TABLE assembly_tagged_contig (
  seq_region_id int(10) NOT NULL DEFAULT 0,
  transferred enum(3) NOT NULL DEFAULT 'no'
);

CREATE UNIQUE INDEX seq_region_id ON assembly_tagged_contig (seq_region_id);

CREATE TABLE gene_name_update (
  gene_id int(10) NOT NULL DEFAULT 0,
  consortium_id varchar(20) NOT NULL DEFAULT '',
  old_name varchar(25) NOT NULL DEFAULT '',
  update_date datetime DEFAULT NULL
);

CREATE UNIQUE INDEX gene_id ON gene_name_update (gene_id);

COMMIT;
