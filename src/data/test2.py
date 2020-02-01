from nba_data_player import *
from nba_data_season import *
from nba_driver import *
from time import sleep
from build_database import *
import traceback
import sys

driver = driver_init()
get_team_schedule(driver, 'ATL', 1997)
