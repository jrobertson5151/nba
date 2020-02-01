import pandas as pd
from nba_driver import *

teams_url = 'https://www.basketball-reference.com/teams/'

def get_season_soup(driver, team, season):
    return get_soup(driver, teams_url + correct_team_url(team, season) +
                    '/' + str(season+1) + '.html')

def get_player_ids(table):
    player_ids = []
    for td in table.find_all('td', attrs={'data-stat': 'player'}):
        player_ids.append(td['data-append-csv'])
    return player_ids

def get_season_table(season_soup, id_name):
    table = season_soup.find('table', id =id_name)
    try:
        df = pd.read_html(str(table))[0]
    except:
        return None
    df['player_id'] = get_player_ids(table)
    df = df.set_index('player_id', drop = False)
    return df    
    
def get_team_roster(season_soup):
    table = season_soup.find('table', id='roster')
    try:
        df = pd.read_html(str(table))[0]
    except:
        return None
        '''player_ids = []
    for td in table.find_all('td', attrs={'data-stat': 'player'}):
        player_ids.append(td['data-append-csv'])'''
    df['player_id'] = get_player_ids(table)
    df = df[['player_id', 'Player', 'No.', 'Pos']]
    df = df.set_index('player_id')
    return df

def get_team_season_info(season_soup):
    try:
        table = season_soup.find('table', id='team_misc')
        table.find('tr', attrs={'class': 'over_header'}).decompose()
        rtn = pd.read_html(str(table))[0]
        rtn.name = None
        rtn.rename(columns={'EFG%.1': 'Opp EFG', 'TOV%.1': 'Opp TOV%',
                            'FT/FGA.1': 'Opp FT/FGA'}, inplace = True)
        return rtn
    except:
        return None

def get_team_per_game(season_soup):
    try:
        df = get_season_table(season_soup, 'per_game')
        return df
    except:
        return None

def get_team_totals(season_soup):
    try:
        for tag in season_soup.find_all('tr', attrs={'class':'stat_average'}):
            tag.decompose()
        df = get_season_table(season_soup, 'totals')
        return df
    except:
        return None

def get_team_per_min(season_soup):
    df = get_season_table(season_soup, 'per_minute')
    return df

def get_team_per_poss(season_soup):
    df = get_season_table(season_soup, 'per_poss')
    return df

def get_team_advanced(season_soup):
    df = get_season_table(season_soup, 'advanced')
    return df

def get_team_shooting(season_soup):
    df = get_season_table(season_soup, 'shooting')
    return df

def get_team_schedule(driver, franch_id, season):
    correct_id = correct_team_url(franch_id, season)
    sched_soup = get_soup(driver,
                          'https://www.basketball-reference.com/teams/' +
                          correct_id + '/' + str(season+1) + '_games.html')
    #[t.decompose() for t in sched_soup.find_all('tr', attrs={'class':'thead'})]
    game_ids = [str.split(td.a['href'], '/')[2][:-5] for td in
                sched_soup.find('div', 
                id='all_games').find_all('td', attrs={'data-stat': 'box_score_text'})]
    sched_df = pd.read_html(str(sched_soup.find('table', id='games')))[0]
    sched_df = sched_df.set_index('G', drop=False)
    sched_df = sched_df[sched_df['G'] != 'G']
    sched_df['Win'] = [True if x == 'W' else False for x in sched_df['Unnamed: 7']]
    sched_df['Home'] = [False if x == '@' else True for x in sched_df['Unnamed: 5']]
    sched_df['Overtimes'] = [0 if pd.isnull(x) else 1 if x == 'OT' else int(x[0])
                             for x in sched_df['Unnamed: 8']]
    filter_empty_columns = [col for col in sched_df if
                            col.startswith('Unnamed') or col == 'Notes']
    sched_df = sched_df.drop(filter_empty_columns, axis=1)
    sched_df['game_id'] = game_ids
    #get franch_id for opponent
    #box scores
    #playoffs
    return sched_df

def get_preseason_odds(driver, year):
    url = 'https://www.basketball-reference.com/leagues/NBA_' + \
          str(year+1) + '_preseason_odds.html'
    odds_soup = get_soup(driver, url)
    if odds_soup is None:
        return None
    table_soup = odds_soup.find('table', id='NBA_preseason_odds')
    if table_soup is None:
        return None
    table = pd.read_html(str(table_soup))[0]
    table = table[table['Team'] != 'Team']
    table.drop(list(table.filter(regex = 'Unnamed')), axis=1, inplace=True)
    table['Odds'] = [float(x) for x in table['Odds']]
    #find franch_ids when you have stored team_name_table
    return table

def get_playoffs_data(driver, year):
    url = 'https://www.basketball-reference.com/playoffs/NBA_' + str(year+1) + '.html'
    playoff_soup = get_soup(driver, url)
    series_data = pd.read_html(str(playoff_soup('table', id='all_playoffs')))[1:]
    stats_dict = dict()
    for s in series_data:
        s.columns = ['Game', 'Date', 'Away', 'Away Pts', 'Home', 'Home Pts']
        s.index += 1 #so it starts at 1
        s.drop(columns=['Game'], inplace=True)
        s['Home'] = s['Home'].str.strip('@ ')
        s.index.name = 'Game Number'

    team_misc = playoff_soup.find('table', id='misc')
    team_misc.find('tr', attrs={'class': 'over_header'}).decompose()
    team_misc_table = pd.read_html(str(team_misc))[0]
    team_misc_table.rename(columns=
                           {'eFG%.1': 'Opp eFG%', 'TOV%.1': 'Opp TOV%', 'FT/FGA.1': 'Opp FT/FGA'},
                           inplace=True)
    team_misc_table = team_misc_table.iloc[:-1]
    return (series_data, team_misc_table)
    
