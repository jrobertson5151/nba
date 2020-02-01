from nba_driver import *

def scrape_odds(driver = None):
    def url_by_year(helper_year):
        part1 = 'https://www.sportsoddshistory.com/nba-main/?y='
        part2 = '&sa=nba&a=finals&o=r'
        return part1+str(helper_year)+'-'+str(helper_year+1)+part2
        
    if driver is None:
        close_at_end = True
        driver = driver_init()
    else:
        close_at_end = False

    rtn = dict()
    for y in range(1978, 2019):
        print('Year is ', y)
        try:
            soup = get_soup(driver, url_by_year(y))
            ts = soup.find('table', class_='soh1')
            ts.find('tr').decompose()
            df = pd.read_html(str(ts))[0]
            df = df.iloc[:, :-1] #kill last column
            correct_cols = ['Team'] + list(df.columns[:-1])
            df.columns = correct_cols
            rtn[y] = df
            sleep(.25)
        except:
            print('couldn\'t handle ', y)
            
    if close_at_end:
        driver.close()

    return rtn
