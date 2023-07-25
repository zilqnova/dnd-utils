#!/usr/bin/env python
import argparse
import re
import random

class Business:
    def __init__(self, balance, upkeep, time, divisor):
        self._balance = balance
        self._upkeep = upkeep
        
        time_match = re.search(r"^([0-9])+([dwmy]){1}$", time, flags=re.IGNORECASE)
        try:
            if not time_match.group(1):
                raise ValueError("No time value supplied")
            self._time = int(time_match.group(1))
        except (ValueError, AttributeError):
            print(parser.error("argument TIME: value is invalid"))
        try:
            if not time_match.group(2):
                raise ValueError("Interval not defined or incorrect")
            self._interval = time_match.group(2)
        except (ValueError, AttributeError):
            print(parser.error("argument TIME: value is invalid"))
        
        match self._interval:
            case "d":
                self._interval = 1
            case "w":
                self._interval = 7
            case "m":
                self._interval = 30
            case "y":
                self._interval = 365
            case _:
                raise ValueError("Interval incorrect; must be d, w, m, or y")
        self._time *= self._interval

        self._divisor = divisor
        #Initialize private variables to 0
        self._bonus = 0
        self._penalty = 0
        self._profit = 0
    
    def _roll(self, number=1, sides=6):
        i = 0
        total = 0
        while i < number:
            total = total + random.randint(1, sides)
            i += 1
        total = total - self._penalty + self._bonus
        if total < 1:
            total = 1
        return total

    def _bonus_increment(self, reset=False):
        if reset == True:
            self._bonus = 0
        if self._bonus < 30:
            self._bonus += 1

    def _penalty_check(self, reset=False):
        if reset == True:
            self._penalty = 0
        if self._balance < 0:
            self._penalty += 10
    
    def run(self):
        i = 0
        while i < self._time:
            roll = self._roll(sides=100)
            profit_old = self._profit
            if 1 <= roll <= 20:
                iteration_profit = self._upkeep * -1.5
            elif 21 <= roll <= 30:
                iteration_profit = self._upkeep * -1
            elif 31 <= roll <= 40:
                iteration_profit = self._upkeep * -0.5
            elif 41 <= roll <= 60:
                iteration_profit = 0
            elif 61 <= roll <= 80:
                iteration_profit = (self._roll() * 5 )/self._divisor
            elif 81 <= roll <= 90:
                iteration_profit = (self._roll(number=2, sides=8) * 5)/self._divisor
            elif 91 <= roll:
                iteration_profit = (self._roll(number=3, sides=10) * 5)/self._divisor
            
            self._profit = round(self._profit + iteration_profit, 2)
            self._balance = round(self._balance + iteration_profit, 2) # Balance is updated each iteration to check for penalty
            self._bonus_increment()
            if self._profit < profit_old:
                self._penalty_check()
            else:
                # The DMG table is not clear if the cumulative -10 penalty is kept even if unpaid debts are paid off.
                # In my opinion, since the penalty is cumulative (which is also subject to debate), it would be unfair not to reset the penalty
                # once the character's balance is above 0.
                self._penalty_check(reset=True)
            
            i += 1
        # Reset bonus and penalty to 0 after run() has completed for future-proofing
        # (e.g., if this class is imported to another program, it could support being run multiple times with persistent profits and balance)
        self._bonus_increment(reset=True)
        self._penalty_check(reset=True)

    @property
    def balance(self):
        return self._balance

    @property
    def upkeep(self):
        return self._upkeep

    @property
    def time(self):
        return self._time

    @property
    def interval(self):
        return self._interval

    @property
    def divisor(self):
        return self._divisor

    @property
    def profit(self):
        return self._profit

parser = argparse.ArgumentParser(description="A script to calculate total business earnings (and losses) in D&D 5e")
parser.add_argument("balance", type=float, help="Character's current amount of gold (can include silver and copper as decimals)", metavar="BALANCE")
parser.add_argument("upkeep", type=float, help="Daily cost of business in gold (can include silver and copper as decimals)", metavar="UPKEEP")
parser.add_argument("time", type=str, help="Amount of time spent running business. Format: number[d,w,m,y], where d is days, w is weeks, m is months, and y is years.", metavar="TIME")
parser.add_argument("--divisor", type=int, help="If your campaign balances gold prices differently, you can specify how much to divide profits by", default=1)
args = parser.parse_args()

def main():
    business = Business(args.balance, args.upkeep, args.time, args.divisor)
    old_balance = business.balance
    business.run()
    if business.balance < old_balance:
        print(f"This business has lost {business.profit}gp. The new balance is {business.balance}gp.")
    elif business.balance == old_balance:
        print(f"This business broke even. The balance is still {business.balance}.")
    else:
        print(f"This business has earned {business.profit}gp. The new balance is {business.balance}gp.")

if __name__ == "__main__":
    main()
