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

ENTRY_FEES = Web3.toWei(0.0001, "ether")
INITIAL_INVESTED_AMOUNT = Web3.toWei(0.001, "ether")

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

    # get_weth(INITIAL_INVESTED_AMOUNT, account)

    if len(CreateTournamentFactory) == 0:
        factory_contract = deploy_factory_contract()
    else:
        factory_contract = CreateTournamentFactory[-1]

    approve_erc20(
        INITIAL_INVESTED_AMOUNT, factory_contract.address, weth_token_address, account
    )
    # tx = interface.ILendingPool(lending_pool_address).deposit(
    #     weth_token_address,
    #     INITIAL_INVESTED_AMOUNT,
    #     account.address,
    #     0,
    #     {"from": account},
    # )
    # print(f"transaction hash is {tx}")
    tournament = factory_contract.createTournamentContract(
        "URI_STRING",
        1650012433,
        1651012433,
        ENTRY_FEES,
        getLendingPoolAddress(),
        weth_token_address,
        INITIAL_INVESTED_AMOUNT,
        {"from": account},
    )
    tournament.wait(1)
    print(f"Tournament created {tournament}")
    tournament_contract = Contract.from_abi(
        CreateTournament._name,
        tournament.events["tournamentCreated"]["tournamentAddress"],
        CreateTournament.abi,
    )
    getBalanceOfContract(tournament_contract)
    # join_tournament(tournament_contract)
    # getBalanceOfContract(tournament_contract)


# This function gets the balance of WETH token placed in the CreateTournament contract created by the user
def getBalanceOfContract(tournament_contract):
    aweth_contract = interface.IERC20(
        config["networks"][network.show_active()]["aweth_token_address"]
    )
    balance_of_contract = aweth_contract.balanceOf(tournament_contract.address)
    print(f"aWeth balance of contract is {balance_of_contract}")


# This Function is used to mimic three accounts joining, basically testing the joining of participants in the event
def join_tournament(tournament_contract):
    new_account = accounts[1]
    print(f"new account 1 : {new_account}")
    print(new_account.balance())
    join = tournament_contract.joinTournament(
        {"from": new_account, "value": ENTRY_FEES}
    )
    join.wait(1)
    new_account = accounts[2]
    print(f"new account 2 : {new_account}")
    join = tournament_contract.joinTournament(
        {"from": new_account, "value": ENTRY_FEES}
    )
    join.wait(1)
    new_account = accounts[3]
    print(f"new account 3 : {new_account}")
    join = tournament_contract.joinTournament(
        {"from": new_account, "value": ENTRY_FEES}
    )
    join.wait(1)
    number_of_participants = tournament_contract.getParticipants()
    print(f"number of participants {number_of_participants}")


def deploy_factory_contract():
    account = get_account()
    createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    print(f"Factory Contract Deployed to {createTournamentFactory}")
    return createTournamentFactory


def main():
    createTournament()
