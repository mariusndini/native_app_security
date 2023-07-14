# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session
from datetime import datetime, timedelta
import numpy as np
import altair as alt
import pandas as pd
session = get_active_session()  
st.set_page_config(layout="centered")

st.write("HI")