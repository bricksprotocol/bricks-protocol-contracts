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
INITIAL_INVESTED_AMOUNT = Web3.toWei(0.001, "ether")

# "URI_STRING", 1650012433, 1651012433, 10000000, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


# get the latest lending pool contract based on the network
def getLendingPoolAddress():
    lending_pool_address_provider = interface.ILendingPoolAddressesProvider(
        config["networks"][network.show_active()]["lending_pool_addresses_provider"]
    )
    lending_pool_address = lending_pool_address_provider.getLendingPool()
    print(f"Lending pool address is {lending_pool_address}")
    return lending_pool_address


# get weth required in the account
def get_weth(amount, account):
    """
    Mints weth while depositing eth
    """
    # get abi and address of the weth contract that will depost eth and give us weth
    print(config["networks"][network.show_active()]["weth_token"])
    print(account)
    weth = interface.IWeth(config["networks"][network.show_active()]["weth_token"])
    if weth.balance() == amount:
        print("balance is already there for weth")
        return
    else:
        tx = weth.deposit({"from": account, "value": amount})
        tx.wait(1)
        print(f"Recieved {amount} weth")
        return tx


def approve_erc20(amount, spender, erc20_address, account):
    print(f"Approving ERC20 token for {spender}")
    # abi and address of the token address
    erc20 = interface.IERC20(erc20_address)
    tx = erc20.approve(spender, amount, {"from": account})
    tx.wait(1)
    print("approved")
    return tx


def deploy_create_tournament():
    account = get_account()
    lending_pool_address = getLendingPoolAddress()
    weth_token_address = config["networks"][network.show_active()]["weth_token"]

    get_weth(INITIAL_INVESTED_AMOUNT, account)

    approve_erc20(
        INITIAL_INVESTED_AMOUNT, lending_pool_address, weth_token_address, account
    )
    # "URI_STRING" ,1650012433, 1651012433, 10000000, 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe, 0xd0a1e359811322d97991e03f863a0c30c2cf029c, 10000000, 0xF0fd5b08889E23cF31495b15cb8687F3e27A1C64
    createTournament = CreateTournament.deploy(
        "URI_STRING",
        1660012433,
        1661012433,
        ENTRY_FEES,
        getLendingPoolAddress(),
        weth_token_address,
        INITIAL_INVESTED_AMOUNT,
        account,
        {"from": account},
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
