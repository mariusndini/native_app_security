-- App Logic Code Base Below
CREATE APPLICATION ROLE IF NOT EXISTS APP_PUBLIC; // role for public objects
CREATE APPLICATION ROLE IF NOT EXISTS APP_ADMIN; // role for ADMIN tasks
CREATE SCHEMA IF NOT EXISTS CORE; // core schema
GRANT USAGE ON SCHEMA CORE TO APPLICATION ROLE APP_PUBLIC; // Make Publically Accessible

CREATE OR ALTER VERSIONED SCHEMA CUSTOMER_DATA; //Create Schema for the Consumer to Use
GRANT USAGE ON SCHEMA CUSTOMER_DATA TO APPLICATION ROLE APP_PUBLIC; // make Publically Accessible
GRANT ALL PRIVILEGES ON SCHEMA CUSTOMER_DATA TO APPLICATION ROLE APP_PUBLIC; //Grant all rights

//In core - create a table w/ the account name in it
CREATE OR REPLACE TABLE CORE.ACCT AS SELECT CURRENT_ACCOUNT() AS ACCT_NAME;
GRANT SELECT ON TABLE CORE.ACCT TO APPLICATION ROLE APP_PUBLIC;
GRANT SELECT ON TABLE CORE.ACCT TO APPLICATION ROLE APP_ADMIN;


-- ONCE WE HAVE ACCESS TO THE NECESSARY OBJECTS
-- RUN PROCEDURE TO CREATE OBJECTS THAT DEPEND ON CONSUMER DATA
CREATE PROCEDURE CORE.CREATE_OBJECTS()
RETURNS STRING
LANGUAGE SQL
AS $$
  BEGIN
    CREATE VIEW IF NOT EXISTS CUSTOMER_DATA.ENRICH as SELECT * FROM reference('enrichment_table');
    GRANT SELECT ON VIEW CUSTOMER_DATA.ENRICH TO APPLICATION ROLE APP_PUBLIC;
    RETURN 'OBJECTS CREATED';
  END;
$$;

GRANT USAGE ON PROCEDURE CORE.CREATE_OBJECTS() TO APPLICATION ROLE APP_ADMIN;


// REGISTER LOCAL OBJECTS WITH THE APPLICATION
CREATE PROCEDURE CORE.REGISTER_CB(ref_name string, operation string, ref_or_alias string)
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

-- ONLY ADMINS FROM THE CONSUMER CAN RUN THIS PROCEDURE
GRANT USAGE ON PROCEDURE CORE.REGISTER_CB(string, string, string) TO APPLICATION ROLE APP_ADMIN;




-- LOAD AND DISPLAY STREAMLIT APPLICATION
-- Providing both location and filename
CREATE OR REPLACE STREAMLIT CUSTOMER_DATA.STREAMLIT
  FROM 'code_artifacts'
  MAIN_FILE = 'streamlit/streamlit_app.py';
GRANT USAGE ON STREAMLIT CUSTOMER_DATA.STREAMLIT TO APPLICATION ROLE APP_PUBLIC;
