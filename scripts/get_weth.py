from scripts.helpful_scripts import get_account
from brownie import interface, config, network

def main():
    get_weth()

def get_weth():
    """
    Mints weth while depositing eth
    """
    # get abi and address of the weth contract that will depost eth and give us weth
    account = get_account()
    print(config["networks"][network.show_active()]["weth_token"])
    print(account)
    weth = interface.IWeth(config["networks"][network.show_active()]["weth_token"])
    tx = weth.deposit({"from": account, "value": 0.1 * 10 ** 18})
    tx.wait(1)
    print("Recieved 0.1 weth")
    return tx