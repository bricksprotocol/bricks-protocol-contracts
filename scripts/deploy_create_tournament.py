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
from web3 import Web3

ENTRY_FEES = Web3.toWei(0.0001, "ether")

# "URI_STRING", 1650012433, 1651012433, 10000000, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


def deploy_create_tournament():
    account = get_account()
    createTournament = CreateTournament.deploy(
        "URI_STRING",
        1660012433,
        1661012433,
        ENTRY_FEES,
        account,
        {"from": account, "value": 1000000000},
    )
    # createTournament.wait(1)
    print(f"Contract Deployed to {createTournament}")
    # get balance of aweth on the address that we used
    aweth_contract = interface.IERC20(
        config["networks"][network.show_active()]["aweth_token_address"]
    )
    balance = aweth_contract.balanceOf(get_account())
    print(f"aWeth balance is {balance}")
    return createTournament


def main():
    deploy_create_tournament()
