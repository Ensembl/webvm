CREATE TABLE otter_accession_info (
            accession_sv    TEXT PRIMARY KEY
            , taxon_id      INTEGER
            , evi_type      TEXT
            , description   TEXT
            , source        TEXT
            , currency      TEXT
            , length        INTEGER
            , sequence      TEXT
        );
CREATE TABLE otter_full_accession (
            name            TEXT PRIMARY KEY
            , accession_sv  TEXT
        );
CREATE TABLE otter_column (
            name            TEXT PRIMARY KEY
            , selected      INTEGER DEFAULT 0
            , status        TEXT
            , status_detail TEXT
            , gff_file      TEXT
            , process_gff   INTEGER DEFAULT 0
        );
CREATE TABLE otter_species_info (
            taxon_id           INTEGER PRIMARY KEY
            , scientific_name  TEXT
            , common_name      TEXT
        );
CREATE TABLE otter_tag_value (
            tag             TEXT PRIMARY KEY
            , value         TEXT
        );
CREATE TABLE otter_otf_request (
            id              INTEGER PRIMARY KEY AUTOINCREMENT
            , logic_name    TEXT NOT NULL
            , target_start  INTEGER
            , command       TEXT NOT NULL
            , fingerprint   TEXT
            , status        TEXT DEFAULT 'new'
            , n_hits        INTEGER
            , transcript_id INTEGER
            , caller_ref    TEXT
            , raw_result    TEXT
        );
CREATE TABLE otter_otf_args (
            request_id      INTEGER NOT NULL
            , key           TEXT NOT NULL
            , value         TEXT
        );
CREATE TABLE otter_otf_missed_hits (
            request_id      INTEGER NOT NULL
            , query_name    TEXT
        );
CREATE INDEX idx_otter_full_accession ON otter_full_accession( accession_sv, name );
