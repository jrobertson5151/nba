from nba_data_player import *
from nba_data_season import *
from nba_driver import *
from time import sleep
from build_database import *
import traceback
import sys
import os.path

driver = driver_init()
franch_ids = ['ATL', 'BOS', 'NJN', 'CHA', 'CHI', 'CLE', 'DAL', 'DEN', 'DET', 'GSW', 'HOU', 'IND', 'LAC', 'LAL', 'MEM', 'MIA', 'MIL', 'MIN', 'NOH', 'NYK', 'OKC', 'ORL', 'PHI', 'PHO', 'POR', 'SAC', 'SAS', 'TOR', 'UTA', 'WAS']
data_loc1 = '../../data/processed/team/'
data_loc2 = '../../data/raw/team/'

try:
    for fi in franch_ids:
        for y in range(1997, 1999):
            print('getting data for ' + fi + '_' + str(y))
            dest_loc = fi + '/' + fi + '_' + str(y) + '/schedule'
            if os.path.exists(data_loc1 + dest_loc):
                print('already exists')
                continue
            try:
                df = get_team_schedule(driver, fi, y)
                sleep(.3)
                df.to_csv(data_loc1 + dest_loc, sep='|')
                df.to_csv(data_loc2 + dest_loc, sep='|')
                print('success')
            except:
                print('failure')
except:
    pass
finally:
    driver.close()
