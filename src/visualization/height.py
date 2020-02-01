from helper import *

def player_height(player_id): #return height in inches
    bio = player_bio(player_id)
    try:
        return 12*bio['height_ft']+bio['height_in']
    except:
        return None

def avg_height_by_season():
    pl = player_list()
    first_year = pl['From'].min()
    last_year = pl['To'].max()
    player_ids = pl['player_id']
    weighted_height = np.zeros(last_year-first_year+1)
    total_minutes = np.zeros(last_year-first_year+1)
    for pi in player_ids:
        totals = player_totals(pi)
        height = player_height(pi)
        if totals is None or height is None:
            continue
        for index, row in totals.iterrows():
            year = int(row['Season'][:4])
            minutes = row['MP']
            if not np.isnan(year) and not np.isnan(minutes):
                weighted_height[year-first_year] += minutes*height
                total_minutes[year-first_year] += minutes
                print(pi, height, year, minutes)
    return pd.Series(weighted_height/total_minutes, index=range(first_year, last_year+1)).dropna()
