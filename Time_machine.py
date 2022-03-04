# TOP SECRET
# Bi-linear Quantum Time machine
# By James Immer

# [Parameters]
import time
import random
import sys
import re
import requests
import json
verbose = False

# [Modules]

#[ Title ]
title_TS = 'TOP SECRET '
title_big = """
  ____                    _                     _______ _                  __  __            _     _                         
 / __ \                  | |                   |__   __(_)                |  \/  |          | |   (_)                        
| |  | |_   _  __ _ _ __ | |_ _   _ _ __ ___      | |   _ _ __ ___   ___  | \  / | __ _  ___| |__  _ _ __   ___              
| |  | | | | |/ _` | '_ \| __| | | | '_ ` _ \     | |  | | '_ ` _ \ / _ \ | |\/| |/ _` |/ __| '_ \| | '_ \ / _ \             
| |__| | |_| | (_| | | | | |_| |_| | | | | | |    | |  | | | | | | |  __/ | |  | | (_| | (__| | | | | | | |  __/             
 \___\_\\__,_|\__,_|_| |_|\__|\__,_|_| |_| |_|    |_|  |_|_| |_| |_|\___| |_|  |_|\__,_|\___|_| |_|_|_| |_|\___|              """
title_name = 'by James Immer'
print(title_TS * 10)
print(title_big)
print(title_name)

time.sleep(3)

# Primary Loop
loop_life = True
while loop_life:

    # Year Selection Matrix
    waiting_for_input = True
    while waiting_for_input:
        first_input = 0
        print('Where would you like to go? (0-2020 AD)')
        first_input = int(input())
        #first_input = int(first_input)
        if first_input > 2020:
            print('Sorry, Future viewing requires Premium licensing')
        if first_input <= 2020:
            time.sleep(1)
            print('Going to year', first_input)
            waiting_for_input = False

    # Quantum Timeframe Analyzer
    goal = True
    while goal:
        # Generates Random Month/date combo
        month = random.randrange(1, 12)
        day = random.randrange(1, 28)
        month = str(month)
        day = str(day)
        url = 'http://history.muffinlabs.com/date' + '/' + month + '/' + day
        if verbose:
            print(url)
        request_raw = requests.get(url)
        request_temp = json.loads(request_raw.text)
        try:
            request_parsed = request_temp["data"]["Events"]
            for event in request_parsed:
                event_year = event["year"]
                if verbose:
                    print(event_year)
                # Skips Event if Year is from BC
                event_is_bc = False
                event_is_AD = False
                try:
                    event_year = (
                        re.search("[0-9]+\s+[a-zA-Z]+", event_year)).group(0)
                    event_is_bc = True
                    if verbose:
                        print('is BC')
                except Exception:
                    try:
                        event_year = (re.search("[0-9]+", event_year)).group(0)
                        event_is_AD = True
                        if verbose:
                            print('is AD')
                    except Exception:
                        pass
                if event_is_bc:
                    if verbose:
                        print('IS BC - Scanning....')
                    del event_is_bc
                if event_is_AD:
                    event_year = int(event_year)
                    del event_is_AD
                    if first_input == event_year:
                        print('MATCH')
                        goal_event = event["text"]
                        goal = False
                    else:
                        if verbose:
                            print('NO MATCH - Scanning....')
                else:
                    if verbose:
                        print('NOT AD/BC - Scanning....')
        except Exception:
            pass

    # [Provide Output to I/O]
    print('CONGRATUATIONS')
    time.sleep(1)
    print('You are now in the year', event_year, '!')
    time.sleep(1)
    event_date = month + '/' + day + '/' + str(event_year)
    print('On', event_date)
    print(goal_event)

    wait_input = True
    event_is_yes = False
    event_is_no = False

    # Optional Loop
    # [first_input Loop]
    while wait_input:
        print('Try another Year? (Y/N)')
        last_input = input()
        try:
            event_year = (re.search("[yn]", last_input)).group(0)
            wait_input = False
            if verbose:
                print('Match')
        except Exception:
            print('first_input was not (Y or N) Please Try Again')
    # [first_input validation]
    try:
        event_year = (re.search("y", last_input)).group(0)
        event_is_yes = True
        if verbose:
            print('Yes')
    except Exception:
        try:
            event_year = (re.search("n", last_input)).group(0)
            event_is_no = True
            if verbose:
                print('No')
            loop_life = False
            print('Thank you!')
        except Exception:
            pass
