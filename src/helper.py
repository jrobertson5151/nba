import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pathlib
import ipdb
import traceback

data_loc= str(pathlib.Path(__file__).parent.parent.absolute())+ '/data/processed'

def player_name(player_id):
    return player_bio(player_id)['Name']
    
def player_df(player_id, table):
    table_loc = data_loc+'/player/' + player_id + '/' + table
    try:
        return pd.read_csv(table_loc, sep='|', index_col=0)
    except:
        return None

def player_bio(player_id):
    bio_df = player_df(player_id, 'bio')
    if bio_df is not None:
        return {att : bio_df[att][0] for att in bio_df.columns}
    else:
        return None

def player_list():
    pl = pd.read_csv(data_loc+'/player_list', sep='|')
    return pl

def player_ids():
    return list(player_list()['player_id'])

def player_totals(player_id):
    return player_df(player_id, 'totals')

def team_list():
    return pd.read_csv(data_loc+'/team_list', sep='|')

def franch_ids():
    return list(team_list()['franch_id'])

def schedule(team, year):
    loc = data_loc+'/team/' + team + '/' + team + '_' + str(year) + '/schedule' 
    df = pd.read_csv(loc, sep = '|')
    df = df.drop(columns=['G.1'])
    return df
