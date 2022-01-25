from brownie import CreateTournamentFactory, config, network, interface
from scripts.helpful_scripts import get_account


def deploy_factory_contract():
    account = get_account()
    createTournamentFactory = CreateTournamentFactory.deploy(
        {"from": account}, publish_source=True
    )
    print(f"Factory Contract Deployed to {createTournamentFactory}")
    # createTournamentFactory.wait(1)
    return createTournamentFactory


def fund_with_link(
    contract_address, account=None, link_token=None, amount=100000000000000000
):
    account = account if account else get_account()
    link_token = (
        link_token
        if link_token
        else config["networks"][network.show_active()]["link_token"]
    )
    # tx = link_token.transfer(contract_address, amount, {"from": account})
    link_token_contract = interface.LinkTokenInterface(link_token)
    tx = link_token_contract.transfer(contract_address, amount, {"from": account})
    tx.wait(1)
    print("fund contract")
    return tx


def main():
    contract = deploy_factory_contract()
    fund_with_link(contract_address=contract)
