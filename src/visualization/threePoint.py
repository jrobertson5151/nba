from helper import *

def three_point_df(players=None):
    if players is None:
        players = player_ids()
    l = []
    for p in players:
        df = player_totals(p)
        try:
            total_3s = df['3P'].sum()
            total_attempts = df['3PA'].sum()
            if total_attempts == 0:
                percent = 0
            else:
                percent = total_3s/total_attempts
            l.append((p, player_name(p), total_3s, total_attempts, percent))
        except:
            pass
    return pd.DataFrame(l, columns=['player_id', 'name', '3P', '3PA', '3P%'])
