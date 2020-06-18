from helper import *

def homecourt_diff(team, year):
    df = schedule(team, year)
    home_wins = sum(df['Home'] & df['Win'])
    away_wins = sum(~df['Home'] & df['Win'])
    return 2*(home_wins-away_wins)/len(df)

def homecourt(years):
    teams = franch_ids()
    rtn = pd.Series(len(years)*[0.], index = years)
    for y in years:
        teams_in_year_y = 0
        sum_of_homecourt_diffs = 0
        for t in teams:
            try:
                #print('getting data for ' + t + ' in year ' + str(y))
                diff = homecourt_diff(t, y)
                sum_of_homecourt_diffs += diff
                teams_in_year_y += 1
                #print('found ' + str(diff))
            except:
                pass# print('failed')
        rtn[y] = sum_of_homecourt_diffs/teams_in_year_y
    return rtn
