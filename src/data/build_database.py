from nba_data_player import *
from nba_data_season import *
from nba_driver import *
from nba_data_betting import *
from time import sleep
import traceback
import sys

data_loc = '../Data/'

def build_db(dest_name='recent', from_year=1990):
    driver = driver_init()
    store = get_store(dest_name)
    try:
        store_seasons(driver, store, range(from_year, 2019))
        store_player_ids(driver, store)
        recent_ids = [x.player_id for (_, x) in store['player_list'].iterrows()
                      if x.From >= from_year]
        store_player_stats(driver, store, recent_ids)
        store_odds(driver, store, range(from_year, 2019))
        store_playoffs_data(driver, store, range(from_year, 2019))
    except:
        traceback.print_exc(file=sys.stdout)
    finally:
        driver.quit()
        store.close()

def get_store(name):
    return pd.HDFStore(data_loc + name + '.h5')

def store_player_ids(driver, store):
    print('Storing player list')
    if 'player_list' not in store:
        store.append('player_list', get_player_id_list(driver))

def store_seasons(driver, store, years, force_update = False):
    if 'team_list' not in store:
        teams_df = get_teams(driver)
        store.append('team_list', teams_df)
    if 'team_name_table' not in store:
        store.append('team_name_table', process_team_table(driver))
    if type(years) is int:
        years = [years]
    for year in years:
        for f in store['team_list']['franch_id']:
            if store['team_list']['From'][f] > year:
                continue
            if f == 'CHA' and year in [2002, 2003, 2004]:
                continue
            print('Getting ' + str(year) +  ' info for ' + f)
            stat_names = ['roster', 'season_info', 'per_game', 'totals',
                          'per_min', 'per_poss', 'advanced']
            if year >= 2000:
                stat_names += ['shooting']
            table_prefix = 'team/' + f + '/' + f + '_' + str(year) + '/'
            matched_stats = sum([table_prefix + stat in store \
                                 for stat in stat_names])
            if (matched_stats == len(stat_names)) or \
                                ((matched_stats > 3) and (force_update is False)):
                #some seasons lack some tables so skip 
                    #if it seems like they're all in the db already
                print('Already have data for ' + f + '_' + str(year))
                continue
            f_soup = get_season_soup(driver, f, year)
            for stat in stat_names:
                table_loc = table_prefix + stat
                if table_loc not in store:
                    table = globals()['get_team_' + stat](f_soup)
                    #ipdb.set_trace()
                    if table is not None:
                        print('Adding ' + table_loc)
                        store.append(table_loc, table)
                    else:
                        print(table_loc + ' not found')
            sleep(1)

def store_player_stats(driver, store, player_ids):
    for player in player_ids:
        print('Storing player stats for ' + player)
        stat_names = ['per_game', 'per_36', 'per_poss', 'advanced', 'shooting',
                      'totals', 'pbp', 'highs', 'bio', 'salaries']
        table_prefix = '/player/' + player
        if table_prefix in store:
            print('Have data for ' + player)
            continue
        player_soup = get_player_soup(driver, player)
        for stat in stat_names:
            for playoff_status in [False, True]:
                playoff_string = ''
                if playoff_status:
                    playoff_string = 'playoff_'
                print('Getting ' + player + ': ' + playoff_string + stat)
                table_loc = table_prefix + '/' + playoff_string + stat
                if table_loc not in store:
                    table = globals()['get_player_' + stat](player_soup, playoff_status)
                    if table is not None:
                        store.append(table_loc, table)
        sleep(1)

def lookup_id(store, team_name):
    if team_name == 'New Orleans/Oklahoma City Hornets':
        return 'NOH'
    return store['team_name_table'].loc[team_name].franch_id
        
def store_preseason_odds(driver, store, years):
    for y in years:
        print('Storing odds for ' + str(y))
        loc = '/season/year_'+str(y)+'/preseason_odds'
        if loc not in store:
            odds = get_preseason_odds(driver, y)
            if odds is None:
                continue
            sleep(.5)
            if 'team_name_table' in store:
                odds['franch_id'] = [lookup_id(store, t) for t in odds['Team']]
            store[loc] = odds
        else:
            print('Already have odds for ' + str(y))

def store_playoffs_data(driver, store, years):
    for y in years:
        print('Storing playoffs data for ' + str(y))
        loc = 'season/year_' + str(y) + '/playoffs'
        if loc+'/playoffs_misc' not in store:
            try:
                (series, misc) = get_playoffs_data(driver, y)
                store[loc +'/playoffs_misc'] = misc
                series_names = ['Finals', 'ECF', 'WCF', 'ECSF1', 'ECSF2', 'WCSF1'
                                , 'WCSF2', 'E1', 'E2', 'E3', 'E4', 'W1', 'W2', 'W3', 'W4']
                for (s, name) in zip(series, series_names):
                    for col in ['Away', 'Home']:
                        s[col+'_id'] = [lookup_id(store, t) for t in s[col]]
                    home_team = lookup_id(store, s.iloc[0]['Home'])
                    away_team = lookup_id(store, s.iloc[0]['Away'])
                    store[loc + '/series/' + name] = s
                    sleep(.5)
            except:
                continue
        else:
            print('Already have data for ' + str(y))    

def store_odds(driver, store, years):
    odds = scrape_odds(driver, years)
    for y in odds:
        print('Storing odds for ', y)
        loc = '/season/year_'+str(y)+'/odds'
        odds[y]['franch_id'] = [lookup_id(store, t) for t in odds[y]['Team']]
        if loc not in store:
            store[loc] = odds[y]
