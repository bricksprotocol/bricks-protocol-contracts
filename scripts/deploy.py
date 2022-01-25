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
from scripts.helpful_scripts import get_account, LOCAL_BLOCKCHAIN_ENV
from scripts.get_weth import get_weth
from web3 import Web3

ENTRY_FEES = Web3.toWei(0.0001, "ether")
INITIAL_INVESTED_AMOUNT = Web3.toWei(0.0001, "ether")

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


# Create factory if needed as well as add one tournament contract to the factory
def createTournament():
    account = get_account()
    lending_pool_address = getLendingPoolAddress()
    weth_token_address = config["networks"][network.show_active()]["weth_token"]

    get_weth(INITIAL_INVESTED_AMOUNT, account)

    if len(CreateTournamentFactory) == 0:
        deploy_factory_contract()

    factory_contract = CreateTournamentFactory[-1]

    print(f"factory address is {factory_contract.address}")

    approve_erc20(
        INITIAL_INVESTED_AMOUNT, factory_contract.address, weth_token_address, account
    )

    # "URI_STRING",1650012433,1651012433,1000000000000000,"0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe","0xd0a1e359811322d97991e03f863a0c30c2cf029c",1000000000000000

    tournament = factory_contract.createTournamentPool(
        "URI_STRING",
        1650012433,
        1651012433,
        ENTRY_FEES,
        lending_pool_address,
        weth_token_address,
        INITIAL_INVESTED_AMOUNT,
        {"from": account},
    )
    tournament.wait(1)
    tournament_address_print = tournament.events["tournamentCreated"][
        "tournamentAddress"
    ]
    print(f"Tournament created {tournament_address_print}")
    tournament_contract = Contract.from_abi(
        CreateTournament._name,
        tournament.events["tournamentCreated"]["tournamentAddress"],
        CreateTournament.abi,
    )
    getBalanceOfAddress(tournament_contract.address, "aweth_token_address")
    join_tournament(tournament_contract)
    getBalanceOfAddress(tournament_contract.address, "aweth_token_address")
    withdraw_funds(tournament_contract)
    getBalanceOfAddress(tournament_contract.address, "aweth_token_address")


# A dummy function not to be used in production
def withdraw_funds(tournament_contract):
    balance = getBalanceOfAddress(get_account(), "weth_token")
    print(f"the weth in the withdrawal account before are {balance}")
    withdraw = tournament_contract.withdrawFunds(
        get_account(),
        config["networks"][network.show_active()]["aweth_token_address"],
        {"from": get_account()},
    )
    withdraw.wait(1)
    balance = getBalanceOfAddress(get_account(), "weth_token")
    print(f"the weth in the withdrawal account are {balance}")


# This function gets the balance of WETH token placed in the CreateTournament contract created by the user
def getBalanceOfAddress(tournament_contract_address, token_string):
    aweth_contract = interface.IERC20(
        config["networks"][network.show_active()][token_string]
    )
    balance_of_address = aweth_contract.balanceOf(tournament_contract_address)
    print(f"aWeth balance of contract is {balance_of_address}")
    return balance_of_address


# This Function is used to mimic three accounts joining, basically testing the joining of participants in the event
def join_tournament(tournament_contract):
    if config["networks"][network.show_active()] in LOCAL_BLOCKCHAIN_ENV:
        new_account = accounts[1]
        get_weth(ENTRY_FEES, new_account)
        print(f"new account 1 : {new_account}")
        print(new_account.balance())
        weth_token_address = config["networks"][network.show_active()]["weth_token"]
        approve_erc20(
            ENTRY_FEES, tournament_contract.address, weth_token_address, new_account
        )
        join = tournament_contract.joinTournament({"from": new_account})
        join.wait(1)
        new_account = accounts[2]
        get_weth(ENTRY_FEES, new_account)
        print(f"new account 2 : {new_account}")
        approve_erc20(
            ENTRY_FEES, tournament_contract.address, weth_token_address, new_account
        )
        join = tournament_contract.joinTournament({"from": new_account})
        join.wait(1)
        new_account = accounts[3]
        get_weth(ENTRY_FEES, new_account)
        print(f"new account 3 : {new_account}")
        approve_erc20(
            ENTRY_FEES, tournament_contract.address, weth_token_address, new_account
        )
        join = tournament_contract.joinTournament({"from": new_account})
        join.wait(1)
        number_of_participants = tournament_contract.getParticipants()
        print(f"number of participants {number_of_participants}")

    else:
        new_account = get_account()
        get_weth(ENTRY_FEES, new_account)
        print(f"new account 1 : {new_account}")
        print(new_account.balance())
        weth_token_address = config["networks"][network.show_active()]["weth_token"]
        approve_erc20(
            ENTRY_FEES, tournament_contract.address, weth_token_address, new_account
        )
        join = tournament_contract.joinTournament({"from": new_account})
        join.wait(1)


def deploy_factory_contract():
    account = get_account()
    createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    print(f"Factory Contract Deployed to {createTournamentFactory}")
    # createTournamentFactory.wait(1)
    return createTournamentFactory


def main():
    createTournament()
