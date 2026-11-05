USE WAREHOUSE LAB_WH;
USE SCHEMA NAVOTI_DB.RAW;

CREATE OR REPLACE TABLE BANK_MASTER (
  Bank           VARCHAR,
  StateLocation  VARCHAR
);

CREATE OR REPLACE TABLE OFFICE_MASTER (
  OfficeCode1  NUMBER,
  OfficeCode2  NUMBER,
  OfficeCode3  NUMBER,
  OfficeName   VARCHAR
);

CREATE OR REPLACE TABLE PRODUCT_MASTER (
  ProductCode       NUMBER,
  ProductName       VARCHAR,
  ProductGroupCode  VARCHAR,
  ProductGroup      VARCHAR
);

CREATE OR REPLACE TABLE SALES_PERSON_MASTER (
  FirstName  VARCHAR,
  LastName   VARCHAR,
  EMail      VARCHAR
);

CREATE OR REPLACE TABLE SALES_TASK_TRANSACTION (
  SalesTaskId        NUMBER,
  Bank               VARCHAR,
  Customer           VARCHAR,
  OfficeCode1        NUMBER,
  OfficeCode2        NUMBER,
  OfficeCode3        NUMBER,
  SalesPerson        VARCHAR,
  ProductCode        NUMBER,
  Channel            VARCHAR,
  ChannelDirection   VARCHAR,
  ReachedStatus      VARCHAR,
  Appointment        VARCHAR,
  SalesResult        VARCHAR,
  State              VARCHAR,
  SalesCreatedDate   DATE,
  SalesStartDate     DATE,
  SalesClosedDate    DATE,
  MarginPercentage   NUMBER(10,4),
  SalesResultAmount  NUMBER(18,2),
  MarginAmount       NUMBER(18,2),
  RewardAmount       NUMBER(18,2),
  SalesTaskCount     NUMBER
);

COPY INTO BANK_MASTER            FROM @raw_stage/BankMaster.csv            FILE_FORMAT = (FORMAT_NAME = csv_load);
COPY INTO OFFICE_MASTER          FROM @raw_stage/OfficeMaster.csv          FILE_FORMAT = (FORMAT_NAME = csv_load);
COPY INTO PRODUCT_MASTER         FROM @raw_stage/ProductMaster.csv         FILE_FORMAT = (FORMAT_NAME = csv_load);
COPY INTO SALES_PERSON_MASTER    FROM @raw_stage/SalesPersonMaster.csv     FILE_FORMAT = (FORMAT_NAME = csv_load);
COPY INTO SALES_TASK_TRANSACTION FROM @raw_stage/SalesTaskTransaction.csv  FILE_FORMAT = (FORMAT_NAME = csv_load);

SELECT 'BANK_MASTER' AS table_name, COUNT(*) AS row_count FROM BANK_MASTER
UNION ALL SELECT 'OFFICE_MASTER',          COUNT(*) FROM OFFICE_MASTER
UNION ALL SELECT 'PRODUCT_MASTER',         COUNT(*) FROM PRODUCT_MASTER
UNION ALL SELECT 'SALES_PERSON_MASTER',    COUNT(*) FROM SALES_PERSON_MASTER
UNION ALL SELECT 'SALES_TASK_TRANSACTION', COUNT(*) FROM SALES_TASK_TRANSACTION;

SELECT OfficeName FROM OFFICE_MASTER LIMIT 5;
