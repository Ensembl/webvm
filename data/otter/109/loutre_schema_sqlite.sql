-- Copyright [2018-2024] EMBL-European Bioinformatics Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Nov 24 15:43:42 2014
-- 

--
-- Table: align_session
--
CREATE TABLE align_session (
  align_session_id INTEGER PRIMARY KEY NOT NULL,
  ref_seq_region_id integer NOT NULL,
  alt_seq_region_id integer NOT NULL,
  alt_db_name varchar(50),
  author varchar(50),
  comment text
);

--
-- Table: align_stage
--
CREATE TABLE align_stage (
  align_stage_id INTEGER PRIMARY KEY NOT NULL,
  align_session_id integer NOT NULL,
  stage varchar(50) NOT NULL,
  ts timestamp NOT NULL DEFAULT current_timestamp,
  script varchar(200) NOT NULL,
  parameters text
);

--
-- Table: alt_allele
--
CREATE TABLE alt_allele (
  alt_allele_id INTEGER PRIMARY KEY NOT NULL,
  alt_allele_group_id integer NOT NULL,
  gene_id integer NOT NULL
);

CREATE UNIQUE INDEX gene_idx ON alt_allele (gene_id);

--
-- Table: alt_allele_attrib
--
CREATE TABLE alt_allele_attrib (
  alt_allele_id integer,
  attrib enum
);

--
-- Table: alt_allele_group
--
CREATE TABLE alt_allele_group (
  alt_allele_group_id INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: analysis
--
CREATE TABLE analysis (
  analysis_id INTEGER PRIMARY KEY NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  logic_name varchar(128) NOT NULL,
  db varchar(120),
  db_version varchar(40),
  db_file varchar(120),
  program varchar(80),
  program_version varchar(40),
  program_file varchar(80),
  parameters text,
  module varchar(80),
  module_version varchar(40),
  gff_source varchar(40),
  gff_feature varchar(40)
);

CREATE UNIQUE INDEX logic_name_idx ON analysis (logic_name);

--
-- Table: analysis_description
--
CREATE TABLE analysis_description (
  analysis_id smallint NOT NULL,
  description text,
  display_label varchar(255) NOT NULL,
  displayable tinyint NOT NULL DEFAULT 1,
  web_data text
);

CREATE UNIQUE INDEX analysis_idx ON analysis_description (analysis_id);

--
-- Table: assembly
--
CREATE TABLE assembly (
  asm_seq_region_id integer NOT NULL,
  cmp_seq_region_id integer NOT NULL,
  asm_start integer NOT NULL,
  asm_end integer NOT NULL,
  cmp_start integer NOT NULL,
  cmp_end integer NOT NULL,
  ori tinyint NOT NULL
);

CREATE UNIQUE INDEX all_idx ON assembly (asm_seq_region_id, cmp_seq_region_id, asm_start, asm_end, cmp_start, cmp_end, ori);

--
-- Table: assembly_exception
--
CREATE TABLE assembly_exception (
  assembly_exception_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  exc_type enum NOT NULL,
  exc_seq_region_id integer NOT NULL,
  exc_seq_region_start integer NOT NULL,
  exc_seq_region_end integer NOT NULL,
  ori integer NOT NULL
);

--
-- Table: assembly_tag
--
CREATE TABLE assembly_tag (
  tag_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL DEFAULT 0,
  seq_region_start integer NOT NULL DEFAULT 0,
  seq_region_end integer NOT NULL DEFAULT 0,
  seq_region_strand tinyint NOT NULL DEFAULT 0,
  tag_type enum NOT NULL DEFAULT 'Misc',
  tag_info text
);

CREATE UNIQUE INDEX seq_region_id ON assembly_tag (seq_region_id, seq_region_start, seq_region_end, seq_region_strand, tag_type, tag_info);

--
-- Table: assembly_tagged_contig
--
CREATE TABLE assembly_tagged_contig (
  seq_region_id integer NOT NULL DEFAULT 0,
  transferred enum NOT NULL DEFAULT 'no'
);

CREATE UNIQUE INDEX seq_region_id02 ON assembly_tagged_contig (seq_region_id);

--
-- Table: associated_group
--
CREATE TABLE associated_group (
  associated_group_id INTEGER PRIMARY KEY NOT NULL,
  description varchar(128)
);

--
-- Table: associated_xref
--
CREATE TABLE associated_xref (
  associated_xref_id INTEGER PRIMARY KEY NOT NULL,
  object_xref_id integer NOT NULL DEFAULT 0,
  xref_id integer NOT NULL DEFAULT 0,
  source_xref_id integer,
  condition_type varchar(128),
  associated_group_id integer,
  rank integer DEFAULT 0
);

CREATE UNIQUE INDEX object_associated_source_type_idx ON associated_xref (object_xref_id, xref_id, source_xref_id, condition_type, associated_group_id);

--
-- Table: attrib_type
--
CREATE TABLE attrib_type (
  attrib_type_id INTEGER PRIMARY KEY NOT NULL,
  code varchar(20) NOT NULL DEFAULT '',
  name varchar(255) NOT NULL DEFAULT '',
  description text
);

CREATE UNIQUE INDEX code_idx ON attrib_type (code);

--
-- Table: author
--
CREATE TABLE author (
  author_id INTEGER PRIMARY KEY NOT NULL,
  author_email varchar(50) NOT NULL DEFAULT '',
  author_name varchar(50) NOT NULL DEFAULT '',
  group_id integer NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX author_email ON author (author_email, group_id);

CREATE UNIQUE INDEX author_name ON author (author_name, author_email);

--
-- Table: author_group
--
CREATE TABLE author_group (
  group_id INTEGER PRIMARY KEY NOT NULL,
  group_name varchar(100) NOT NULL DEFAULT '',
  group_email varchar(50)
);

CREATE UNIQUE INDEX gn_idx ON author_group (group_name);

--
-- Table: contig_attrib
--
CREATE TABLE contig_attrib (
  contig_info_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

--
-- Table: contig_info
--
CREATE TABLE contig_info (
  contig_info_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  is_current tinyint NOT NULL DEFAULT 1
);

--
-- Table: contig_lock
--
CREATE TABLE contig_lock (
  contig_lock_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0,
  hostname varchar(100) NOT NULL DEFAULT '',
  timestamp datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

CREATE UNIQUE INDEX seq_region_id03 ON contig_lock (seq_region_id);

--
-- Table: coord_system
--
CREATE TABLE coord_system (
  coord_system_id INTEGER PRIMARY KEY NOT NULL,
  species_id integer NOT NULL DEFAULT 1,
  name varchar(40) NOT NULL,
  version varchar(255),
  rank integer NOT NULL,
  attrib varchar
);

CREATE UNIQUE INDEX name_idx ON coord_system (name, version, species_id);

CREATE UNIQUE INDEX rank_idx ON coord_system (rank, species_id);

--
-- Table: data_file
--
CREATE TABLE data_file (
  data_file_id INTEGER PRIMARY KEY NOT NULL,
  coord_system_id integer NOT NULL,
  analysis_id smallint NOT NULL,
  name varchar(100) NOT NULL,
  version_lock tinyint NOT NULL DEFAULT 0,
  absolute tinyint NOT NULL DEFAULT 0,
  url text,
  file_type enum
);

CREATE UNIQUE INDEX df_unq_idx ON data_file (coord_system_id, analysis_id, name, file_type);

--
-- Table: density_feature
--
CREATE TABLE density_feature (
  density_feature_id INTEGER PRIMARY KEY NOT NULL,
  density_type_id integer NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  density_value float NOT NULL
);

--
-- Table: density_type
--
CREATE TABLE density_type (
  density_type_id INTEGER PRIMARY KEY NOT NULL,
  analysis_id smallint NOT NULL,
  block_size integer NOT NULL,
  region_features integer NOT NULL,
  value_type enum NOT NULL
);

CREATE UNIQUE INDEX analysis_idx02 ON density_type (analysis_id, block_size, region_features);

--
-- Table: dependent_xref
--
CREATE TABLE dependent_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  master_xref_id integer NOT NULL,
  dependent_xref_id integer NOT NULL
);

--
-- Table: ditag
--
CREATE TABLE ditag (
  ditag_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(30) NOT NULL,
  type varchar(30) NOT NULL,
  tag_count smallint NOT NULL DEFAULT 1,
  sequence tinytext NOT NULL
);

--
-- Table: ditag_feature
--
CREATE TABLE ditag_feature (
  ditag_feature_id INTEGER PRIMARY KEY NOT NULL,
  ditag_id integer NOT NULL DEFAULT 0,
  ditag_pair_id integer NOT NULL DEFAULT 0,
  seq_region_id integer NOT NULL DEFAULT 0,
  seq_region_start integer NOT NULL DEFAULT 0,
  seq_region_end integer NOT NULL DEFAULT 0,
  seq_region_strand tinyint NOT NULL DEFAULT 0,
  analysis_id smallint NOT NULL DEFAULT 0,
  hit_start integer NOT NULL DEFAULT 0,
  hit_end integer NOT NULL DEFAULT 0,
  hit_strand tinyint NOT NULL DEFAULT 0,
  cigar_line tinytext NOT NULL,
  ditag_side enum NOT NULL
);

--
-- Table: dna
--
CREATE TABLE dna (
  seq_region_id INTEGER PRIMARY KEY NOT NULL,
  sequence longtext NOT NULL
);

--
-- Table: dna_align_feature
--
CREATE TABLE dna_align_feature (
  dna_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  hit_start integer NOT NULL,
  hit_end integer NOT NULL,
  hit_strand tinyint NOT NULL,
  hit_name varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision,
  evalue double precision,
  perc_ident float,
  cigar_line text,
  external_db_id integer,
  hcoverage double precision,
  external_data text
);

--
-- Table: dna_spliced_align_feature
--
CREATE TABLE dna_spliced_align_feature (
  dna_spliced_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  hit_start integer NOT NULL,
  hit_end integer NOT NULL,
  hit_strand tinyint NOT NULL,
  hit_name varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision,
  evalue double precision,
  perc_ident float,
  alignment_type text,
  alignment_string text,
  external_db_id integer,
  hcoverage double precision,
  external_data text
);

--
-- Table: evidence
--
CREATE TABLE evidence (
  transcript_id integer NOT NULL DEFAULT 0,
  name varchar(40) NOT NULL DEFAULT '',
  type enum NOT NULL DEFAULT 'EST',
  PRIMARY KEY (transcript_id, name, type)
);

--
-- Table: exon
--
CREATE TABLE exon (
  exon_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  phase tinyint NOT NULL,
  end_phase tinyint NOT NULL,
  is_current tinyint NOT NULL DEFAULT 1,
  is_constitutive tinyint NOT NULL DEFAULT 0,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

--
-- Table: exon_stable_id_pool
--
CREATE TABLE exon_stable_id_pool (
  exon_pool_id INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: exon_transcript
--
CREATE TABLE exon_transcript (
  exon_id integer NOT NULL,
  transcript_id integer NOT NULL,
  rank integer NOT NULL,
  PRIMARY KEY (exon_id, transcript_id, rank)
);

--
-- Table: external_db
--
CREATE TABLE external_db (
  external_db_id INTEGER PRIMARY KEY NOT NULL,
  db_name varchar(100) NOT NULL,
  db_release varchar(255),
  status enum NOT NULL,
  priority integer NOT NULL,
  db_display_name varchar(255),
  type enum,
  secondary_db_name varchar(255),
  secondary_db_table varchar(255),
  description text
);

CREATE UNIQUE INDEX db_name_db_release_idx ON external_db (db_name, db_release);

--
-- Table: external_synonym
--
CREATE TABLE external_synonym (
  xref_id integer NOT NULL,
  synonym varchar(100) NOT NULL,
  PRIMARY KEY (xref_id, synonym)
);

--
-- Table: gene
--
CREATE TABLE gene (
  gene_id INTEGER PRIMARY KEY NOT NULL,
  biotype varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  display_xref_id integer,
  source varchar(20) NOT NULL,
  status enum,
  description text,
  is_current tinyint NOT NULL DEFAULT 1,
  canonical_transcript_id integer NOT NULL,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

--
-- Table: gene_archive
--
CREATE TABLE gene_archive (
  gene_stable_id varchar(128) NOT NULL,
  gene_version smallint NOT NULL DEFAULT 1,
  transcript_stable_id varchar(128) NOT NULL,
  transcript_version smallint NOT NULL DEFAULT 1,
  translation_stable_id varchar(128),
  translation_version smallint NOT NULL DEFAULT 1,
  peptide_archive_id integer,
  mapping_session_id integer NOT NULL
);

--
-- Table: gene_attrib
--
CREATE TABLE gene_attrib (
  gene_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

CREATE UNIQUE INDEX gene_attribx ON gene_attrib (gene_id, attrib_type_id, value);

--
-- Table: gene_author
--
CREATE TABLE gene_author (
  gene_id INTEGER PRIMARY KEY NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0
);

--
-- Table: gene_name_update
--
CREATE TABLE gene_name_update (
  gene_id integer NOT NULL DEFAULT 0,
  consortium_id varchar(20) NOT NULL DEFAULT '',
  old_name varchar(25) NOT NULL DEFAULT '',
  update_date datetime
);

CREATE UNIQUE INDEX gene_id ON gene_name_update (gene_id);

--
-- Table: gene_stable_id_pool
--
CREATE TABLE gene_stable_id_pool (
  gene_pool_id INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: genome_statistics
--
CREATE TABLE genome_statistics (
  genome_statistics_id INTEGER PRIMARY KEY NOT NULL,
  statistic varchar(128) NOT NULL,
  value integer NOT NULL DEFAULT 0,
  species_id integer DEFAULT 1,
  attrib_type_id integer,
  timestamp datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

CREATE UNIQUE INDEX stats_uniq ON genome_statistics (statistic, attrib_type_id, species_id);

--
-- Table: identity_xref
--
CREATE TABLE identity_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  xref_identity integer,
  ensembl_identity integer,
  xref_start integer,
  xref_end integer,
  ensembl_start integer,
  ensembl_end integer,
  cigar_line text,
  score double precision,
  evalue double precision
);

--
-- Table: interpro
--
CREATE TABLE interpro (
  interpro_ac varchar(40) NOT NULL,
  id varchar(40) NOT NULL
);

CREATE UNIQUE INDEX accession_idx ON interpro (interpro_ac, id);

--
-- Table: intron_supporting_evidence
--
CREATE TABLE intron_supporting_evidence (
  intron_supporting_evidence_id INTEGER PRIMARY KEY NOT NULL,
  analysis_id smallint NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  hit_name varchar(100) NOT NULL,
  score decimal(10,3),
  score_type enum DEFAULT 'NONE',
  is_splice_canonical tinyint NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX analysis_id ON intron_supporting_evidence (analysis_id, seq_region_id, seq_region_start, seq_region_end, seq_region_strand, hit_name);

--
-- Table: karyotype
--
CREATE TABLE karyotype (
  karyotype_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  band varchar(40),
  stain varchar(40)
);

--
-- Table: map
--
CREATE TABLE map (
  map_id INTEGER PRIMARY KEY NOT NULL,
  map_name varchar(30) NOT NULL
);

--
-- Table: mapping_session
--
CREATE TABLE mapping_session (
  mapping_session_id INTEGER PRIMARY KEY NOT NULL,
  old_db_name varchar(80) NOT NULL DEFAULT '',
  new_db_name varchar(80) NOT NULL DEFAULT '',
  old_release varchar(5) NOT NULL DEFAULT '',
  new_release varchar(5) NOT NULL DEFAULT '',
  old_assembly varchar(20) NOT NULL DEFAULT '',
  new_assembly varchar(20) NOT NULL DEFAULT '',
  created datetime NOT NULL
);

--
-- Table: mapping_set
--
CREATE TABLE mapping_set (
  mapping_set_id INTEGER PRIMARY KEY NOT NULL,
  internal_schema_build varchar(20) NOT NULL,
  external_schema_build varchar(20) NOT NULL
);

CREATE UNIQUE INDEX mapping_idx ON mapping_set (internal_schema_build, external_schema_build);

--
-- Table: marker
--
CREATE TABLE marker (
  marker_id INTEGER PRIMARY KEY NOT NULL,
  display_marker_synonym_id integer,
  left_primer varchar(100) NOT NULL,
  right_primer varchar(100) NOT NULL,
  min_primer_dist integer NOT NULL,
  max_primer_dist integer NOT NULL,
  priority integer,
  type enum
);

--
-- Table: marker_feature
--
CREATE TABLE marker_feature (
  marker_feature_id INTEGER PRIMARY KEY NOT NULL,
  marker_id integer NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  analysis_id smallint NOT NULL,
  map_weight integer
);

--
-- Table: marker_map_location
--
CREATE TABLE marker_map_location (
  marker_id integer NOT NULL,
  map_id integer NOT NULL,
  chromosome_name varchar(15) NOT NULL,
  marker_synonym_id integer NOT NULL,
  position varchar(15) NOT NULL,
  lod_score double precision,
  PRIMARY KEY (marker_id, map_id)
);

--
-- Table: marker_synonym
--
CREATE TABLE marker_synonym (
  marker_synonym_id INTEGER PRIMARY KEY NOT NULL,
  marker_id integer NOT NULL,
  source varchar(20),
  name varchar(50)
);

--
-- Table: meta
--
CREATE TABLE meta (
  meta_id INTEGER PRIMARY KEY NOT NULL,
  species_id integer DEFAULT 1,
  meta_key varchar(40) NOT NULL,
  meta_value varchar(255)
);

CREATE UNIQUE INDEX species_key_value_idx ON meta (species_id, meta_key, meta_value);

--
-- Table: meta_coord
--
CREATE TABLE meta_coord (
  table_name varchar(40) NOT NULL,
  coord_system_id integer NOT NULL,
  max_length integer
);

CREATE UNIQUE INDEX cs_table_name_idx ON meta_coord (coord_system_id, table_name);

--
-- Table: misc_attrib
--
CREATE TABLE misc_attrib (
  misc_feature_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

CREATE UNIQUE INDEX misc_attribx ON misc_attrib (misc_feature_id, attrib_type_id, value);

--
-- Table: misc_feature
--
CREATE TABLE misc_feature (
  misc_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL DEFAULT 0,
  seq_region_start integer NOT NULL DEFAULT 0,
  seq_region_end integer NOT NULL DEFAULT 0,
  seq_region_strand tinyint NOT NULL DEFAULT 0
);

--
-- Table: misc_feature_misc_set
--
CREATE TABLE misc_feature_misc_set (
  misc_feature_id integer NOT NULL DEFAULT 0,
  misc_set_id smallint NOT NULL DEFAULT 0,
  PRIMARY KEY (misc_feature_id, misc_set_id)
);

--
-- Table: misc_set
--
CREATE TABLE misc_set (
  misc_set_id INTEGER PRIMARY KEY NOT NULL,
  code varchar(25) NOT NULL DEFAULT '',
  name varchar(255) NOT NULL DEFAULT '',
  description text NOT NULL,
  max_length integer NOT NULL
);

CREATE UNIQUE INDEX code_idx02 ON misc_set (code);

--
-- Table: object_xref
--
CREATE TABLE object_xref (
  object_xref_id INTEGER PRIMARY KEY NOT NULL,
  ensembl_id integer NOT NULL,
  ensembl_object_type enum NOT NULL,
  xref_id integer NOT NULL,
  linkage_annotation varchar(255),
  analysis_id smallint NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX xref_idx ON object_xref (xref_id, ensembl_object_type, ensembl_id, analysis_id);

--
-- Table: ontology_xref
--
CREATE TABLE ontology_xref (
  object_xref_id integer NOT NULL DEFAULT 0,
  source_xref_id integer,
  linkage_type varchar(3)
);

CREATE UNIQUE INDEX object_source_type_idx ON ontology_xref (object_xref_id, source_xref_id, linkage_type);

--
-- Table: operon
--
CREATE TABLE operon (
  operon_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  display_label varchar(255),
  analysis_id smallint NOT NULL,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

--
-- Table: operon_transcript
--
CREATE TABLE operon_transcript (
  operon_transcript_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  operon_id integer NOT NULL,
  display_label varchar(255),
  analysis_id smallint NOT NULL,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

--
-- Table: operon_transcript_gene
--
CREATE TABLE operon_transcript_gene (
  operon_transcript_id integer,
  gene_id integer
);

--
-- Table: peptide_archive
--
CREATE TABLE peptide_archive (
  peptide_archive_id INTEGER PRIMARY KEY NOT NULL,
  md5_checksum varchar(32),
  peptide_seq mediumtext NOT NULL
);

--
-- Table: prediction_exon
--
CREATE TABLE prediction_exon (
  prediction_exon_id INTEGER PRIMARY KEY NOT NULL,
  prediction_transcript_id integer NOT NULL,
  exon_rank smallint NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  start_phase tinyint NOT NULL,
  score double precision,
  p_value double precision
);

--
-- Table: prediction_transcript
--
CREATE TABLE prediction_transcript (
  prediction_transcript_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  analysis_id smallint NOT NULL,
  display_label varchar(255)
);

--
-- Table: protein_align_feature
--
CREATE TABLE protein_align_feature (
  protein_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL DEFAULT 1,
  hit_start integer NOT NULL,
  hit_end integer NOT NULL,
  hit_name varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision,
  evalue double precision,
  perc_ident float,
  cigar_line text,
  external_db_id integer,
  hcoverage double precision
);

--
-- Table: protein_feature
--
CREATE TABLE protein_feature (
  protein_feature_id INTEGER PRIMARY KEY NOT NULL,
  translation_id integer NOT NULL,
  seq_start integer NOT NULL,
  seq_end integer NOT NULL,
  hit_start integer NOT NULL,
  hit_end integer NOT NULL,
  hit_name varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision,
  evalue double precision,
  perc_ident float,
  external_data text,
  hit_description text
);

--
-- Table: protein_spliced_align_feature
--
CREATE TABLE protein_spliced_align_feature (
  protein_spliced_align_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL DEFAULT 1,
  hit_start integer NOT NULL,
  hit_end integer NOT NULL,
  hit_name varchar(40) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision,
  evalue double precision,
  perc_ident float,
  alignment_type text,
  alignment_string text,
  external_db_id integer,
  hcoverage double precision
);

--
-- Table: repeat_consensus
--
CREATE TABLE repeat_consensus (
  repeat_consensus_id INTEGER PRIMARY KEY NOT NULL,
  repeat_name varchar(255) NOT NULL,
  repeat_class varchar(100) NOT NULL,
  repeat_type varchar(40) NOT NULL,
  repeat_consensus text
);

--
-- Table: repeat_feature
--
CREATE TABLE repeat_feature (
  repeat_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL DEFAULT 1,
  repeat_start integer NOT NULL,
  repeat_end integer NOT NULL,
  repeat_consensus_id integer NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision
);

--
-- Table: seq_region
--
CREATE TABLE seq_region (
  seq_region_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(40) NOT NULL,
  coord_system_id integer NOT NULL,
  length integer NOT NULL
);

CREATE UNIQUE INDEX name_cs_idx ON seq_region (name, coord_system_id);

--
-- Table: seq_region_attrib
--
CREATE TABLE seq_region_attrib (
  seq_region_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

CREATE UNIQUE INDEX region_attribx ON seq_region_attrib (seq_region_id, attrib_type_id, value);

--
-- Table: seq_region_mapping
--
CREATE TABLE seq_region_mapping (
  external_seq_region_id integer NOT NULL,
  internal_seq_region_id integer NOT NULL,
  mapping_set_id integer NOT NULL
);

--
-- Table: seq_region_synonym
--
CREATE TABLE seq_region_synonym (
  seq_region_synonym_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  synonym varchar(40) NOT NULL,
  external_db_id integer
);

CREATE UNIQUE INDEX syn_idx ON seq_region_synonym (synonym);

--
-- Table: sequence_note
--
CREATE TABLE sequence_note (
  seq_region_id integer NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0,
  note_time datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  is_current enum NOT NULL DEFAULT 'no',
  note text,
  PRIMARY KEY (seq_region_id, author_id, note_time)
);

--
-- Table: sequence_set_access
--
CREATE TABLE sequence_set_access (
  seq_region_id integer NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0,
  access_type enum NOT NULL DEFAULT 'R',
  PRIMARY KEY (seq_region_id, author_id)
);

--
-- Table: simple_feature
--
CREATE TABLE simple_feature (
  simple_feature_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  display_label varchar(255) NOT NULL,
  analysis_id smallint NOT NULL,
  score double precision
);

--
-- Table: slice_lock
--
CREATE TABLE slice_lock (
  slice_lock_id INTEGER PRIMARY KEY NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  author_id integer NOT NULL,
  ts_begin datetime NOT NULL,
  ts_activity datetime NOT NULL,
  active enum NOT NULL,
  freed enum,
  freed_author_id integer,
  intent varchar(100) NOT NULL,
  hostname varchar(100) NOT NULL,
  otter_version varchar(16),
  ts_free datetime
);

--
-- Table: stable_id_event
--
CREATE TABLE stable_id_event (
  old_stable_id varchar(128),
  old_version smallint,
  new_stable_id varchar(128),
  new_version smallint,
  mapping_session_id integer NOT NULL DEFAULT 0,
  type enum NOT NULL,
  score float NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX uni_idx ON stable_id_event (mapping_session_id, old_stable_id, new_stable_id, type);

--
-- Table: supporting_feature
--
CREATE TABLE supporting_feature (
  exon_id integer NOT NULL DEFAULT 0,
  feature_type enum,
  feature_id integer NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX all_idx02 ON supporting_feature (exon_id, feature_type, feature_id);

--
-- Table: tmp_align
--
CREATE TABLE tmp_align (
  tmp_align_id INTEGER PRIMARY KEY NOT NULL,
  align_session_id integer NOT NULL,
  alt_start integer NOT NULL,
  alt_end integer NOT NULL,
  ref_start integer NOT NULL,
  ref_end integer NOT NULL
);

--
-- Table: tmp_mask
--
CREATE TABLE tmp_mask (
  tmp_mask_id INTEGER PRIMARY KEY NOT NULL,
  tmp_align_id integer NOT NULL,
  alt_mask_start integer,
  alt_mask_end integer,
  ref_mask_start integer,
  ref_mask_end integer
);

--
-- Table: transcript
--
CREATE TABLE transcript (
  transcript_id INTEGER PRIMARY KEY NOT NULL,
  gene_id integer,
  analysis_id smallint NOT NULL,
  seq_region_id integer NOT NULL,
  seq_region_start integer NOT NULL,
  seq_region_end integer NOT NULL,
  seq_region_strand tinyint NOT NULL,
  display_xref_id integer,
  source varchar(20) NOT NULL DEFAULT 'ensembl',
  biotype varchar(40) NOT NULL,
  status enum,
  description text,
  is_current tinyint NOT NULL DEFAULT 1,
  canonical_translation_id integer,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

CREATE UNIQUE INDEX canonical_translation_idx ON transcript (canonical_translation_id);

--
-- Table: transcript_attrib
--
CREATE TABLE transcript_attrib (
  transcript_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

CREATE UNIQUE INDEX transcript_attribx ON transcript_attrib (transcript_id, attrib_type_id, value);

--
-- Table: transcript_author
--
CREATE TABLE transcript_author (
  transcript_id INTEGER PRIMARY KEY NOT NULL DEFAULT 0,
  author_id integer NOT NULL DEFAULT 0
);

--
-- Table: transcript_intron_supporting_evidence
--
CREATE TABLE transcript_intron_supporting_evidence (
  transcript_id integer NOT NULL,
  intron_supporting_evidence_id integer NOT NULL,
  previous_exon_id integer NOT NULL,
  next_exon_id integer NOT NULL,
  PRIMARY KEY (intron_supporting_evidence_id, transcript_id)
);

--
-- Table: transcript_stable_id_pool
--
CREATE TABLE transcript_stable_id_pool (
  transcript_pool_id INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: transcript_supporting_feature
--
CREATE TABLE transcript_supporting_feature (
  transcript_id integer NOT NULL DEFAULT 0,
  feature_type enum,
  feature_id integer NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX all_idx03 ON transcript_supporting_feature (transcript_id, feature_type, feature_id);

--
-- Table: translation
--
CREATE TABLE translation (
  translation_id INTEGER PRIMARY KEY NOT NULL,
  transcript_id integer NOT NULL,
  seq_start integer NOT NULL,
  start_exon_id integer NOT NULL,
  seq_end integer NOT NULL,
  end_exon_id integer NOT NULL,
  stable_id varchar(128),
  version smallint NOT NULL DEFAULT 1,
  created_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
);

--
-- Table: translation_attrib
--
CREATE TABLE translation_attrib (
  translation_id integer NOT NULL DEFAULT 0,
  attrib_type_id smallint NOT NULL DEFAULT 0,
  value text NOT NULL
);

CREATE UNIQUE INDEX translation_attribx ON translation_attrib (translation_id, attrib_type_id, value);

--
-- Table: translation_stable_id_pool
--
CREATE TABLE translation_stable_id_pool (
  translation_pool_id INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: unmapped_object
--
CREATE TABLE unmapped_object (
  unmapped_object_id INTEGER PRIMARY KEY NOT NULL,
  type enum NOT NULL,
  analysis_id smallint NOT NULL,
  external_db_id integer,
  identifier varchar(255) NOT NULL,
  unmapped_reason_id smallint NOT NULL,
  query_score double precision,
  target_score double precision,
  ensembl_id integer DEFAULT 0,
  ensembl_object_type enum DEFAULT 'RawContig',
  parent varchar(255)
);

CREATE UNIQUE INDEX unique_unmapped_obj_idx ON unmapped_object (ensembl_id, ensembl_object_type, identifier, unmapped_reason_id, parent, external_db_id);

--
-- Table: unmapped_reason
--
CREATE TABLE unmapped_reason (
  unmapped_reason_id INTEGER PRIMARY KEY NOT NULL,
  summary_description varchar(255),
  full_description varchar(255)
);

--
-- Table: xref
--
CREATE TABLE xref (
  xref_id INTEGER PRIMARY KEY NOT NULL,
  external_db_id integer NOT NULL,
  dbprimary_acc varchar(40) NOT NULL,
  display_label varchar(128) NOT NULL,
  version varchar(10) NOT NULL DEFAULT '0',
  description text,
  info_type enum NOT NULL DEFAULT 'NONE',
  info_text varchar(255) NOT NULL
);

CREATE UNIQUE INDEX id_index ON xref (dbprimary_acc, external_db_id, info_type, info_text, version);
