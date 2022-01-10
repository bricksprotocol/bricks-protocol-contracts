# this script will be used to deploy the bricks contracts

from brownie import (
    CreateTournamentFactory,
    config,
    network,
    accounts,
    CreateTournament,
    Contract,
    interface,
)
from scripts.helpful_scripts import get_account
from scripts.get_weth import get_weth
from web3 import Web3

# This function gets the balance of WETH token placed in the CreateTournament contract created by the user
def getBalanceOfAddress(tournament_contract_address, token_string):
    aweth_contract = interface.IERC20(
        config["networks"][network.show_active()][token_string]
    )
    balance_of_address = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_address}")
    return balance_of_address


# A dummy function not to be used in production
def withdraw_funds(tournament_address, address_to_withdraw):
    tournament_contract = tournament_contract = Contract.from_abi(
        CreateTournament._name,
        tournament_address,
        CreateTournament.abi,
    )
    balance = getBalanceOfAddress(address_to_withdraw, "weth_token")
    print(f"the weth in the withdrawal account before are {balance}")
    withdraw = tournament_contract.withdrawFunds(
        address_to_withdraw,
        config["networks"][network.show_active()]["aweth_token_address"],
        {"from": address_to_withdraw},
    )
    withdraw.wait(1)
    balance = getBalanceOfAddress(address_to_withdraw, "weth_token")
    print(f"the weth in the withdrawal account are {balance}")


def main():
    tournament_address = ""
    address_to_withdraw = ""
    withdraw_funds(tournament_address, address_to_withdraw)
