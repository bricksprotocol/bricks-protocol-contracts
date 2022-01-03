from brownie import (
    CreateTournamentFactory,
    CreateTournament,
    network,
    config,
    interface,
    Contract,
)


def get_balance():
    tournament_contract_address = "0x92f4c3F968DD8A6CeBb07A581718811733534503"
    aweth_contract = interface.IERC20("0xFF3c8bc103682FA918c954E84F5056aB4DD5189d")
    balance_of_contract = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_contract}")


def main():
    get_balance()
