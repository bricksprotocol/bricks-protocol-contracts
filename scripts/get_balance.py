from brownie import (
    CreateTournamentFactory,
    CreateTournament,
    network,
    config,
    interface,
    Contract,
)


def get_balance():
    tournament_contract_address = CreateTournamentFactory[-1].tournamentsArray(0)
    aweth_contract = interface.IERC20(
        config["networks"][network.show_active()]["aweth_token_address"]
    )
    balance_of_contract = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_contract}")


def main():
    get_balance()
