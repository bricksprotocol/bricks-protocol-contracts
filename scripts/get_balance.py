from brownie import (
    CreateTournamentFactory,
    CreateTournament,
    network,
    config,
    interface,
    Contract,
)


def get_balance():
    tournament_contract_address = "0xda1A24f14D0eaC4F0a8c661AA42dbd512A7F0cF3"
    aweth_contract = interface.IERC20("0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347")
    balance_of_contract = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_contract}")


def main():
    get_balance()
