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
st.write('Streamlit can be used to build a UI to open alongside the application.')
st.write('1) An admin dashboard to help set up application')
st.write('2) Charts and analytics on Application')
st.write('3) External Function to reach out to external services')
st.write('etc.')