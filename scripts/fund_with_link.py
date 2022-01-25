from scripts.helpful_scripts import get_account
from brownie import config, network, interface


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
    fund_with_link(contract_address="0xdA8c99fc563B2b1181D1690771670bA488415Fe7")
