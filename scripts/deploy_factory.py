from brownie import CreateTournamentFactory
from scripts.helpful_scripts import get_account


def deploy_factory_contract():
    account = get_account()
    createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    print(f"Factory Contract Deployed to {createTournamentFactory}")
    # createTournamentFactory.wait(1)
    return createTournamentFactory


def main():
    deploy_factory_contract()
