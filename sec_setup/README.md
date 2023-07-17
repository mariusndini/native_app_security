# Snowflake Native App: Security Features and Usage Guide
Docs as of: 7/11/2023
Contact: Marius.Ndini@Snowflake.com

Welcome to the ReadMe for our Snowflake Native Application, where we provide an overview of its security features for Native apps.

Our application delivers data to developers, including both private data accessible only to the application and chargeable data based on the number of data assets requested. Prices are as follows: 1 Ticker costs $x, 2 tickers cost $2X, and 3 tickers cost $3X.





---

## Pre-Reqs after installation
1) Have table with following data:
```SQL
CREATE OR REPLACE TABLE YOUR_DB.YOUR_SCHEMA.YOUR_TABLE (
   asset_id varchar,
   quantity DECIMAL(18, 2),
   currency VARCHAR(3),
   timestamp TIMESTAMP
);
```

2) Register objects with the Application. SQL Below or via Snowsight user interface. 

```SQL
CALL MY_INSTALLED_APP.CORE.REGISTER_CB(
    'holdings_table'
    ,'ADD'
    , SYSTEM$REFERENCE('TABLE', 'YOUR_DB.YOUR_SCHEMA.YOUR_TABLE', 'PERSISTENT', 'SELECT') );

```

---

### After Install
Opionally give access to the following Application rols to approriate roles to your Snowflake account. 
If all else fails try AccountAdmin

```SQL
SHOW APPLICATION ROLES IN MY_INSTALLED_APP;
GRANT APPLICATION ROLE MY_INSTALLED_APP.APP_ADMIN TO ROLE <YOUR ADMIN ROLE>;
GRANT APPLICATION ROLE MY_INSTALLED_APP.APP_PUBLIC TO ROLE <YOUR PUBLIC/USER ROLE>;
```

1) **APP_ADMIN** has the ability to run the following procedures
    **REGISTER_OBJECTS()** Giving access to local objects to application
    **CREATE_OBJECTS()** After access has been granted, procedure will create objects for consumer to select from.
2) **APP_PUBLIC** After the above has been run the consumer will have access to APP_DB.CONSUMER_DATA.**CURRENT_PRICE** table. 

---

## Application Chart
    /Native App Database/
        Schema: Core/
            Procedures/
                REGISTER_OBJECTS()
                CREATE_OBJECTS()
            Tables/
                ACCT
        Schema: customer_data/
                Schema available to your account to create objects as necessary
        Schema: shared_data/
            streamlit/
                streamlit_app install
                public data/
                    Data made available to you via tables and/or views
                Private Data/
                    Data used by the app but not made available to your account
        Roles/
            APP_ADMIN: Admin task role for application
            APP_PUBLIC: publically available objects
        
        

