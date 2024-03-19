# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session
from datetime import datetime, timedelta
import numpy as np
import altair as alt
import pandas as pd
session = get_active_session()  
st.set_page_config(layout="centered")

st.header("Native App - Security")

holdings = session.sql(f"""select * 
                          from reference('holdings_table')
                          order by ASSET_ID;""").to_pandas()


holdings_df = pd.DataFrame(holdings)

st.table(holdings_df)



# PUT file:///Users/mndini/Documents/GitHub/native_app_security/sec_setup/code_artifacts/streamlit/streamlit_app.py  @NATIVE_APP_SECURITY.SEC.STAGE/sec_setup/code_artifacts/streamlit overwrite=true auto_compress=false;