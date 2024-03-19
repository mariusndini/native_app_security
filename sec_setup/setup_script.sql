-- App Logic Code Base Below
CREATE APPLICATION ROLE IF NOT EXISTS APP_PUBLIC; // role for public objects
CREATE APPLICATION ROLE IF NOT EXISTS APP_ADMIN; // role for ADMIN tasks
CREATE SCHEMA IF NOT EXISTS CORE; // core schema - unversioned will live thru patches & versions
GRANT USAGE ON SCHEMA CORE TO APPLICATION ROLE APP_ADMIN; // Make Publically Accessible
GRANT USAGE ON SCHEMA CORE TO APPLICATION ROLE APP_PUBLIC; // Make Publically Accessible

// A PLACE WHERE CONSUMERS CAN STORE THEIR DATA AND SUCH
CREATE OR ALTER VERSIONED SCHEMA CUSTOMER_DATA; //Create VERSIONED Schema for the Consumer to Use - resets every patch/version
GRANT USAGE ON SCHEMA CUSTOMER_DATA TO APPLICATION ROLE APP_PUBLIC; // make Publically Accessible
GRANT ALL PRIVILEGES ON SCHEMA CUSTOMER_DATA TO APPLICATION ROLE APP_PUBLIC; //Grant all rights to consumer

-- SCHEMA WHERE SHARED DATA LIVES
CREATE SCHEMA IF NOT EXISTS SHARED_DATA; 
GRANT USAGE ON SCHEMA SHARED_DATA TO APPLICATION ROLE APP_PUBLIC;


// In core - create a table w/ the account name in it
// This table stores the account name and can be used for any filtering 
// or any other logic where specific Snowflake Account Name is needed
CREATE TABLE IF NOT EXISTS CORE.ACCT AS SELECT CURRENT_ACCOUNT() AS ACCT_NAME; //make table
GRANT SELECT ON TABLE CORE.ACCT TO APPLICATION ROLE APP_PUBLIC; //Give SELECT to public
GRANT SELECT ON TABLE CORE.ACCT TO APPLICATION ROLE APP_ADMIN;//Give SELECT To admin


-- ONCE WE HAVE ACCESS TO THE NECESSARY OBJECTS
-- RUN PROCEDURE TO CREATE OBJECTS THAT DEPEND ON CONSUMER DATA
-- Job will combine delivered data and consumer information
-- It will also create a BILLING_EVENT on how many securities consumer asked for. 
CREATE OR REPLACE PROCEDURE CORE.CREATE_OBJECTS()
RETURNS string
LANGUAGE SQL
AS $$

  BEGIN
    CREATE VIEW IF NOT EXISTS CUSTOMER_DATA.CURRENT_VALUE as 
          select SYMBOL, PRICE, QUANTITY, PRICE * QUANTITY AS CURRENT_VALUE, HT.CURRENCY
                 FROM SHARED_DATA.CURRENT_PRICE CP
                 INNER JOIN reference('holdings_table') HT ON CP.SYMBOL = HT.ASSET_ID;
    
    GRANT SELECT ON VIEW CUSTOMER_DATA.CURRENT_VALUE TO APPLICATION ROLE APP_PUBLIC;

    -- SELECT SYSTEM$CREATE_BILLING_EVENT( 'BILLING_EVENT','',1689615708000, 1689615708000 , 1,'','');

    RETURN 'DONE';

  END;
$$;



-- Give access to APP_ADMIN to create objects
GRANT USAGE ON PROCEDURE CORE.CREATE_OBJECTS() TO APPLICATION ROLE APP_ADMIN;


// REGISTER LOCAL OBJECTS WITH THE APPLICATION
// Give the UI and the Consumer the ability to associate local objects
// to needed objects for the application
CREATE OR REPLACE PROCEDURE CORE.REGISTER_CB(ref_name string, operation string, ref_or_alias string)
RETURNS STRING
LANGUAGE SQL
AS $$
    begin
        case (operation)
            when 'ADD' then
                select system$set_reference(:ref_name, :ref_or_alias);
            when 'REMOVE' then
                select system$remove_reference(:ref_name);
            when 'CLEAR' then
                select system$remove_reference(:ref_name);
            else
                return 'Unknown operation: ' || operation;
        end case;
        system$log('debug', 'register_single_callback: ' || operation || ' succeeded');
        return 'Operation ' || operation || ' succeeded';
    end;
$$;
-- Give access to the APP ADMIN
GRANT USAGE ON PROCEDURE CORE.REGISTER_CB(string, string, string) TO APPLICATION ROLE APP_ADMIN;













CREATE VIEW IF NOT EXISTS SHARED_DATA.MINUTE_TICKS as SELECT * FROM DATA.MINUTE_TICKS;

------------------------------------------------------------------------------------------
-- BY NOT GRANTING ACCESS TO ROLE APP_PUBLIC THIS TABLE CAN STAY HIDDEN
-- AND MADE ONLY ACCESSIBLE VIA THE APPLICATION

-- GRANT SELECT ON VIEW SHARED_DATA.MINUTE_TICKS TO APPLICATION ROLE APP_PUBLIC; -- the consumer can access

CREATE VIEW IF NOT EXISTS SHARED_DATA.MINUTE_TICKS_LIMITED as SELECT * FROM DATA.MINUTE_TICKS LIMIT 1000;
GRANT SELECT ON VIEW SHARED_DATA.MINUTE_TICKS_LIMITED TO APPLICATION ROLE APP_PUBLIC;




/* RUN DATA TRANSFORMATION JOB
   Simple transformation job utilizing Consumer compute
 */
CREATE OR REPLACE TABLE SHARED_DATA.CURRENT_PRICE AS
  with MX_DATE AS(
    select SYMBOL, MAX(STARTTIME) AS MX
    from SHARED_DATA.MINUTE_TICKS  
    group by 1
  )
  select MT.SYMBOL AS SYMBOL, CLOSE AS PRICE, STARTTIME AS T
  from SHARED_DATA.MINUTE_TICKS MT
  inner join MX_DATE ON MX_DATE.SYMBOL = MT.SYMBOL AND MX_DATE.MX = STARTTIME
;


GRANT SELECT ON VIEW SHARED_DATA.CURRENT_PRICE TO APPLICATION ROLE APP_PUBLIC; -- the consumer can access






-- LOAD AND DISPLAY STREAMLIT APPLICATION
-- Providing both location and filename
-- Make it accssible to the public role - not admin
CREATE OR REPLACE STREAMLIT SHARED_DATA.STREAMLIT
  FROM '/code_artifacts/streamlit'
  MAIN_FILE = '/streamlit_app.py';

GRANT USAGE ON STREAMLIT SHARED_DATA.STREAMLIT TO APPLICATION ROLE APP_PUBLIC;


CREATE OR REPLACE STREAMLIT SHARED_DATA.STREAMLIT_HOLDINGS
  FROM '/code_artifacts/streamlit'
  MAIN_FILE = '/holdings.py';

GRANT USAGE ON STREAMLIT SHARED_DATA.STREAMLIT_HOLDINGS TO APPLICATION ROLE APP_PUBLIC;







-- CREATE AND SEND BILLING EVENT
-- FOR CUSTOM BILLING OPTIONS
create or replace procedure CORE.MAKE_BILLING_EVENT(ASSETS_COUNT float)
  returns string
  language javascript
  as     
  $$  
   
  var event_ts = Date.now();
  var objects = "[ \"A LIST OF DELIVERED OBJECTS\" ]";

  var res = snowflake.createStatement({
    sqlText: `SELECT SYSTEM$CREATE_BILLING_EVENT('PROC_CALL',
                                            'SUB_CLASS',
                                            ${event_ts},
                                            ${event_ts},
                                            ${ASSETS_COUNT},
                                            '${objects}',
                                            '')`   }).execute();
    res.next();

  return `Billed for ${ASSETS_COUNT} securities`;


  $$
  ;

