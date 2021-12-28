# this script will be used to deploy the bricks contracts

from brownie import (
    CreateTournamentFactory,
    config,
    network,
    accounts,
    CreateTournament,
    Contract,
)
from scripts.helpful_scripts import get_account
from web3 import Web3

ENTRY_FEES = Web3.toWei(0.0001, "ether")


def createTournament():
    # account = get_account()
    # createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    # print(f"Contract Deployed to {createTournamentFactory}")
    print(CreateTournamentFactory)
    if len(CreateTournamentFactory) == 0:
        factory_contract = deploy_factory_contract()
    else:
        factory_contract = CreateTournamentFactory[-1]
    tournament = factory_contract.createTournamentContract(
        "URI_STRING", 1650012433, 1651012433, ENTRY_FEES, {"from": get_account()}
    )
    tournament.wait(1)
    print(f"the tournamnet is hosted at {tournament}")
    print(tournament.events["tournamentCreated"]["tournamentAddress"])
    # join_tournament(tournament)


def join_tournament(tournament):
    contract = Contract.from_abi(
        CreateTournament._name,
        tournament.events["tournamentCreated"]["tournamentAddress"],
        CreateTournament.abi,
    )
    new_account = accounts[1]
    print(f"new account 1 : {new_account}")
    join = contract.joinTournament({"from": new_account, "value": ENTRY_FEES})
    join.wait(1)
    new_account = accounts[2]
    print(f"new account 2 : {new_account}")
    join = contract.joinTournament({"from": new_account, "value": ENTRY_FEES})
    join.wait(1)
    new_account = accounts[3]
    print(f"new account 3 : {new_account}")
    join = contract.joinTournament({"from": new_account, "value": ENTRY_FEES})
    join.wait(1)
    number_of_participants = contract.getParticipants()
    print(f"number of participants {number_of_participants}")


# "URI_STRING", 1650012433, 1651012433, 10000000, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


def deploy_factory_contract():
    account = get_account()
    createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    print(f"Contract Deployed to {createTournamentFactory}")
    return createTournamentFactory


def main():
    createTournament()
