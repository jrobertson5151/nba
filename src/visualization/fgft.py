from helper import *

def fgft():
    pl = player_list()
    player_ids = pl['player_id']
    l = list()
    for pi in player_ids:
        try:
            totals = player_totals(pi)
            fga = totals['FGA'].sum()
            fg = totals['FG'].sum()
            fta = totals['FTA'].sum()
            ft = totals['FT'].sum()
            pn = player_name(pi)
            l.append((pi, pn, fg, fga, ft, fta))
        except:
            print('no data for ' + pi)
    return pd.DataFrame(l, columns=['player_id', 'Player', 'FG', 'FGA', 'FT', 'FTA'])
