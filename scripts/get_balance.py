from brownie import (
    CreateTournamentFactory,
    CreateTournament,
    network,
    config,
    interface,
    Contract,
)


def get_balance():
    tournament_contract_address = "0x4a2DF83ea349753D1DA773d2e2223F1C1Bf5d89E"
    aweth_contract = interface.IERC20("0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347")
    balance_of_contract = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_contract}")


def main():
    get_balance()
