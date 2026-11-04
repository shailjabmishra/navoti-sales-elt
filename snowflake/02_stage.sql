-- =====================================================================
-- 02_stage.sql : external stage over the Azure Blob container "raw"
-- =====================================================================
-- The SAS token must allow resource types Container + Object (srt=co or sco)
-- and at least Read + List. A token with srt=c can LIST files but every
-- read fails with "Failed to access remote file: access denied".
--
-- Never commit a real token. Paste it here only in your Snowsight worksheet.

USE WAREHOUSE LAB_WH;
USE SCHEMA NAVOTI_DB.RAW;

CREATE OR REPLACE STAGE raw_stage
  URL = 'azure://navoti0hands0on.blob.core.windows.net/raw/'
  CREDENTIALS = (AZURE_SAS_TOKEN = '<SAS_TOKEN>')   -- without the leading "?"
  FILE_FORMAT = csv_load;

-- Should list 5 files:
-- BankMaster.csv, OfficeMaster.csv, ProductMaster.csv,
-- SalesPersonMaster.csv, SalesTaskTransaction.csv
LIST @raw_stage;

-- Read test (needs object-level access in the SAS token)
SELECT $1, $2 FROM @raw_stage/BankMaster.csv (FILE_FORMAT => 'csv_plain') LIMIT 5;

-- When the token is renewed:
-- ALTER STAGE raw_stage SET CREDENTIALS = (AZURE_SAS_TOKEN = '<NEW_SAS_TOKEN>');
