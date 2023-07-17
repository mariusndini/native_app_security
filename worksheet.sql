------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- CREATE LOCAL DATABASE TO STORE APPLICATION FILES---------------------------------------------
------------------------------------------------------------------------------------------------

// CREATE DB TO STORE APP FILES
// This DB, Schema & stage only exists for the app files to live - can be DB
create database native_app_security;
create schema sec; // MAKE SCHEMA AS WELL

use warehouse app_wh;

// CREATE STAGE FOR THE FILES
// Files will be uploaded and then these files are used in the installation process
CREATE OR REPLACE STAGE native_app_security.sec.stage
  FILE_FORMAT = (TYPE = 'csv' FIELD_DELIMITER = '|' SKIP_HEADER = 1);

// Show all files
list @NATIVE_APP_SECURITY.SEC.STAGE;
// Drop stage if necessary
-- DROP STAGE native_app_security.sec.stage;

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- CREATE THE APPLICATION PACKAGE --------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
CREATE APPLICATION PACKAGE native_app_sec_package;

// CREATE THE APPLICATION FROM THE FILES IN STAGE
// Will create an application package from the files in the stage
CREATE APPLICATION native_app_sec_application
  FROM APPLICATION PACKAGE native_app_sec_package
  USING '@NATIVE_APP_SECURITY.SEC.STAGE/sec_setup';

//LIST ALL APP-PACKAGES IN ACCOUNT
SHOW APPLICATION PACKAGES;

//ADD VERSION TO APP PACKAGE (ONLY 2 LIVE VERSIONS ALLOWED)
ALTER APPLICATION PACKAGE native_app_sec_package
  ADD VERSION V1 
  USING '@NATIVE_APP_SECURITY.SEC.STAGE/sec_setup';



//ADD PATCH FOR A LIVE VERSION (V1 HERE) UNLIMITED ALLOWED
ALTER APPLICATION PACKAGE native_app_sec_package 
ADD PATCH 
  FOR VERSION V1
  USING '@NATIVE_APP_SECURITY.SEC.STAGE/sec_setup';

------------------------------------------------------------------------------------------------
-- CREATE APPLICATION  -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------


//LIST VERSIONS
SHOW VERSIONS IN APPLICATION PACKAGE native_app_sec_package;

------------------------------------------------------------------------------------------------
-- LOCALLY INSTALL THE APPLICATION -------------------------------------------------------------
-- MAKE SURE TO UPDATE THE PATCH NUMBER --------------------------------------------------------
------------------------------------------------------------------------------------------------
DROP APPLICATION native_app_sec_application;

// INSTALL APPLICATION FROM THE APP-PACKAGE
// This app is installed from the version & patch specified in the app apckage above
CREATE APPLICATION native_app_sec_application
  FROM APPLICATION PACKAGE native_app_sec_package
  USING VERSION V1
  PATCH 88;

//SHOW SCHEMAS IN APP
show schemas in database native_app_sec_application;


------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- GIVE ACCESS TO APP ROLES TO LOCAL USERS -----------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

-- DESCRIBE THE APP
describe application native_app_sec_application;

-- SHOW ROLES IN APP DATABASE
-- These roles can be assigned to local roles in the Consumer account
show application roles in native_app_sec_application;

//GRANT APPLICATION ROLE TO LOCAL ROLE
-- Users that belong to the local role will have access to interact with the objects in the app
GRANT APPLICATION ROLE native_app_sec_application.APP_PUBLIC TO ROLE LOCAL_ROLE;

// They can create tables in the Native App
-- assuming they have priviledges to do so
CREATE TABLE NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.C_TABLE (V VARIANT);

// Data can be inserted in the application
INSERT INTO NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.C_TABLE (select PARSE_JSON('{"Time":"'||current_timestamp()||'"}') );
//They can query data in the application
select *
from NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.C_TABLE;

// Views can be created in the App
CREATE VIEW NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.C_VIEW as
select *
from CITIBIKE.DEMO.NEIGHBORHOODS;

SELECT *
FROM NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.C_VIEW
LIMIT 10;



-------------------------------------------------------------------------------------
-- NOT ALLOWED TO OPERATE
-- Because users have not been given rights to interact with the CORE Schema they cant 
-- create a table there.
CREATE TABLE NATIVE_APP_SEC_APPLICATION.CORE.C_TABLE (V VARIANT);

// They can select data from the CORE schema. 
// These rights have been given
SELECT *
FROM NATIVE_APP_SEC_APPLICATION.CORE.ACCT;

CREATE SCHEMA native_app_sec_package.DATA;


GRANT REFERENCE_USAGE ON DATABASE STOCKS TO SHARE IN APPLICATION PACKAGE native_app_sec_package;
GRANT USAGE ON SCHEMA native_app_sec_package.DATA TO SHARE IN APPLICATION PACKAGE native_app_sec_package;
CREATE VIEW native_app_sec_package.DATA.MINUTE_TICKS AS SELECT * FROM STOCKS.PRICE.MINUTE_TICKS;
GRANT SELECT ON VIEW native_app_sec_package.DATA.MINUTE_TICKS TO SHARE IN APPLICATION PACKAGE native_app_sec_package;




-- CONSUMER TASKS BELOW - 
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- REFERENCE & PRIVILEGES IN APPLICATION   -----------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

//Show list of consumer objects needed by the application
SHOW REFERENCES IN APPLICATION NATIVE_APP_SEC_APPLICATION;
// SHOW LIST OF ACCOUNT LEVEL PRIVILEGES APPLICATION NEEDS TO RUN
SHOW PRIVILEGES IN APPLICATION NATIVE_APP_SEC_APPLICATION;

-- SHOW ROLES IN APP DATABASE
-- These roles can be assigned to local roles in the Consumer account
show application roles in native_app_sec_application;

GRANT EXECUTE TASK ON ACCOUNT TO APPLICATION NATIVE_APP_SEC_APPLICATION;

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO APPLICATION NATIVE_APP_SEC_APPLICATION;


-- REGISTER LOCAL OBJECTS WITH THE DATABASE
-- Meaning - give access to local objects to the application to access
CALL NATIVE_APP_SEC_APPLICATION.CORE.REGISTER_CB(
    'holdings_table'
    ,'ADD'
    , SYSTEM$REFERENCE('TABLE', 'LOCAL_DB.PUBLIC.HOLDINGS', 'PERSISTENT', 'SELECT', 'INSERT', 'UPDATE') );

//Test - selecting from reference object and normal object
SELECT * FROM reference('holdings_table');


//create objects in database to do things with
CALL NATIVE_APP_SEC_APPLICATION.CORE.CREATE_OBJECTS();


select *
from NATIVE_APP_SEC_APPLICATION.CUSTOMER_DATA.CURRENT_VALUE
;












SELECT listing_global_name,
   listing_display_name,
   charge_type,
   charge
FROM SNOWFLAKE.DATA_SHARING_USAGE.MARKETPLACE_PAID_USAGE_DAILY
-- WHERE charge_type='MONETIZABLE_BILLING_EVENTS'
limit 10
;



