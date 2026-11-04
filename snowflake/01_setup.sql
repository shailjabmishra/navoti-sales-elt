-- =====================================================================
-- 01_setup.sql : warehouse, database, schema and file formats
-- Run in a Snowsight worksheet as a role that can create these objects.
-- =====================================================================

CREATE WAREHOUSE IF NOT EXISTS LAB_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60            -- pause after 1 minute idle to save credits
  INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE LAB_WH;

CREATE DATABASE IF NOT EXISTS NAVOTI_DB;
CREATE SCHEMA   IF NOT EXISTS NAVOTI_DB.RAW;
USE SCHEMA NAVOTI_DB.RAW;

-- Used for loading: skips the header, handles the source quirks found while profiling
CREATE OR REPLACE FILE FORMAT csv_load
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE                 -- OfficeName has a leading space
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  DATE_FORMAT = 'DD/MM/YYYY'        -- dates are day/month/year, e.g. 14/02/2007
  ENCODING = 'ISO-8859-1';          -- Finnish characters (ä, ö) are Latin-1, not UTF-8

-- Used only to preview files ($1, $2, ...) straight from the stage
CREATE OR REPLACE FILE FORMAT csv_plain
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';
