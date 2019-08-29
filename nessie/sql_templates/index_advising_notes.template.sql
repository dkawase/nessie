/**
 * Copyright ©2019. The Regents of the University of California (Regents). All Rights Reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its documentation
 * for educational, research, and not-for-profit purposes, without fee and without a
 * signed licensing agreement, is hereby granted, provided that the above copyright
 * notice, this paragraph and the following two paragraphs appear in all copies,
 * modifications, and distributions.
 *
 * Contact The Office of Technology Licensing, UC Berkeley, 2150 Shattuck Avenue,
 * Suite 510, Berkeley, CA 94720-1620, (510) 643-7201, otl@berkeley.edu,
 * http://ipira.berkeley.edu/industry-info for commercial licensing opportunities.
 *
 * IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF
 * THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS HAS BEEN ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
 * SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED
 * "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS.
 */

CREATE SCHEMA IF NOT EXISTS {rds_schema_advising_notes};
GRANT USAGE ON SCHEMA {rds_schema_advising_notes} TO {rds_app_boa_user};
ALTER DEFAULT PRIVILEGES IN SCHEMA {rds_schema_advising_notes} GRANT SELECT ON TABLES TO {rds_app_boa_user};

BEGIN TRANSACTION;

DROP TABLE IF EXISTS {rds_schema_advising_notes}.advising_note_author_names CASCADE;

CREATE TABLE {rds_schema_advising_notes}.advising_note_author_names
(
    uid VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    PRIMARY KEY (uid, name)
);

CREATE INDEX IF NOT EXISTS advising_note_author_names_name_idx
ON {rds_schema_advising_notes}.advising_note_author_names (name);

INSERT INTO {rds_schema_advising_notes}.advising_note_author_names (
    SELECT DISTINCT uid, unnest(string_to_array(
        regexp_replace(upper(first_name), '[^\w ]', '', 'g'),
        ' '
    )) AS name FROM {rds_schema_advising_notes}.advising_note_authors
    UNION
    SELECT DISTINCT uid, unnest(string_to_array(
        regexp_replace(upper(last_name), '[^\w ]', '', 'g'),
        ' '
    )) AS name FROM {rds_schema_advising_notes}.advising_note_authors
);

DROP TABLE IF EXISTS {rds_schema_advising_notes}.advising_notes CASCADE;

CREATE TABLE {rds_schema_advising_notes}.advising_notes AS (
SELECT sis.sid, sis.id, sis.note_body, sis.advisor_sid,
       NULL::varchar AS advisor_uid, NULL::varchar AS advisor_first_name, NULL::varchar AS advisor_last_name,
       sis.note_category, sis.note_subcategory, sis.created_by, sis.created_at, sis.updated_at
FROM {rds_schema_sis_advising_notes}.advising_notes sis
UNION
SELECT ascn.sid, ascn.id, NULL AS note_body, NULL AS advisor_sid, ascn.advisor_uid, ascn.advisor_first_name, ascn.advisor_last_name,
       NULL AS note_category, NULL AS note_subcategory, NULL AS created_by, ascn.created_at, ascn.updated_at
FROM {rds_schema_asc}.advising_notes ascn
UNION
SELECT ein.sid, ein.id, NULL AS note_body, NULL AS advisor_sid, ein.advisor_uid, ein.advisor_first_name, ein.advisor_last_name,
       NULL AS note_category, NULL AS note_subcategory, NULL AS created_by, ein.created_at, ein.updated_at
FROM {rds_schema_e_i}.advising_notes ein
);

CREATE INDEX idx_sis_advising_notes_id ON {rds_schema_advising_notes}.advising_notes(id);
CREATE INDEX idx_sis_advising_notes_sid ON {rds_schema_advising_notes}.advising_notes(sid);
CREATE INDEX idx_sis_advising_notes_advisor_sid ON {rds_schema_advising_notes}.advising_notes(advisor_sid);
CREATE INDEX idx_sis_advising_notes_advisor_uid ON {rds_schema_advising_notes}.advising_notes(advisor_uid);
CREATE INDEX idx_sis_advising_notes_created_at ON {rds_schema_advising_notes}.advising_notes(created_at);
CREATE INDEX idx_sis_advising_notes_created_by ON {rds_schema_advising_notes}.advising_notes(created_by);
CREATE INDEX idx_sis_advising_notes_updated_at ON {rds_schema_advising_notes}.advising_notes(updated_at);

DROP MATERIALIZED VIEW IF EXISTS {rds_schema_advising_notes}.advising_notes_search_index CASCADE;

CREATE MATERIALIZED VIEW {rds_schema_advising_notes}.advising_notes_search_index AS (
  SELECT id, fts_index FROM {rds_schema_asc}.advising_notes_search_index
  UNION SELECT id, fts_index FROM {rds_schema_e_i}.advising_notes_search_index
  UNION SELECT id, fts_index FROM {rds_schema_sis_advising_notes}.advising_notes_search_index
);

CREATE INDEX idx_advising_notes_ft_search
ON {rds_schema_advising_notes}.advising_notes_search_index
USING gin(fts_index);

COMMIT TRANSACTION;
