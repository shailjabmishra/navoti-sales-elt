USE WAREHOUSE LAB_WH;
USE SCHEMA NAVOTI_DB.RAW;

CREATE OR REPLACE STAGE raw_stage
  URL = 'azure://navoti0hands0on.blob.core.windows.net/raw/'
  CREDENTIALS = (AZURE_SAS_TOKEN = '<SAS_TOKEN>')
  FILE_FORMAT = csv_load;

LIST @raw_stage;

SELECT $1, $2 FROM @raw_stage/BankMaster.csv (FILE_FORMAT => 'csv_plain') LIMIT 5;
