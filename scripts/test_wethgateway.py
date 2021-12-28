from brownie import interface, network, config
from scripts.helpful_scripts import get_account


def test_iweth_gateway():
    account = get_account()
    lending_pool = interface.ILendingPoolAddressesProvider(
        config["networks"][network.show_active()]["lending_pool_addresses_provider"]
    ).getLendingPool()
    # print(lending_pool.getLendingPool())
    tx = interface.IWETHGateway(
        config["networks"][network.show_active()]["weth_gateway_aave"]
    ).depositETH(lending_pool, account, 0, {"from": account, "value": 100000000})
    tx.wait(1)


def main():
    test_iweth_gateway()
