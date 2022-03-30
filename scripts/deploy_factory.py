from brownie import CreateTournamentFactory, config, network, interface, Contract
from scripts.helpful_scripts import get_account
from web3 import Web3

# deploy the factory contract
def deploy_factory_contract():
    account = get_account()
    # createTournamentFactory = CreateTournamentFactory.deploy(
    #     {"from": account}, publish_source=True
    # )
    createTournamentFactory = CreateTournamentFactory.deploy({"from": account})
    print(f"Factory Contract Deployed to {createTournamentFactory}")
    # createTournamentFactory.wait(1)
    return createTournamentFactory


# fund the contract with link
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


# set link token address for the contract
def set_link_token_address(contract_address):
    factory_contract = Contract.from_abi(
        CreateTournamentFactory._name,
        contract_address,
        CreateTournamentFactory.abi,
    )
    link_token_address = config["networks"][network.show_active()]["link_token"]
    tx = factory_contract.setLinkTokenAddress(
        link_token_address, {"from": get_account()}
    )
    tx.wait(1)
    print(f"Link token address set to {link_token_address}")


# set oracle job id and oracle id along with fees
def set_oracle_data(contract_address):
    factory_contract = Contract.from_abi(
        CreateTournamentFactory._name,
        contract_address,
        CreateTournamentFactory.abi,
    )
    oracle = config["networks"][network.show_active()]["oracle_id"]
    job = config["networks"][network.show_active()]["job_id"]
    fees = Web3.toWei(config["networks"][network.show_active()]["oracle_fees"], "ether")
    tx = factory_contract.setOracleData(oracle, job, fees, {"from": get_account()})
    tx.wait(1)
    print(f"oracle set to {oracle} {job} {fees}")


# set minimum link to fund while creating an event
def set_minimum_link_funder(contract_address, minimum_link_for_contract_funder):
    factory_contract = Contract.from_abi(
        CreateTournamentFactory._name,
        contract_address,
        CreateTournamentFactory.abi,
    )
    tx = factory_contract.setMinimumLinkfunder(
        Web3.toWei(minimum_link_for_contract_funder, "ether"), {"from": get_account()}
    )
    tx.wait(1)
    print(f"minimum link for funder set to {minimum_link_for_contract_funder}")


# set the lending pool address provider
def set_lending_pool_address_provider(contract_address):
    factory_contract = Contract.from_abi(
        CreateTournamentFactory._name,
        contract_address,
        CreateTournamentFactory.abi,
    )
    lending_pool_addresses_provider = config["networks"][network.show_active()][
        "lending_pool_addresses_provider"
    ]
    tx = factory_contract.setLendingPoolAddressProvider(
        lending_pool_addresses_provider, {"from": get_account()}
    )
    tx.wait(1)
    print(f"lending pool address provider set to {lending_pool_addresses_provider}")


#  set protocol fees in percentage
def set_protocol_fees(contract_address):
    factory_contract = Contract.from_abi(
        CreateTournamentFactory._name,
        contract_address,
        CreateTournamentFactory.abi,
    )
    tx = factory_contract.setProtocolFees(1000, {"from": get_account()})
    tx.wait(1)
    print(f"protocol fees set to {1000}")


def main():
    # Below code will only be able to create 5 participants per event, and you would be able to create only 4 tournaments because the link token will be exhaused
    contract = deploy_factory_contract()
    set_link_token_address(contract_address=contract)
    set_oracle_data(contract_address=contract)
    set_lending_pool_address_provider(contract_address=contract)

    # Amount of link tokens to start a contract
    minimum_link_for_contract_funder = 0.5
    set_minimum_link_funder(contract, minimum_link_for_contract_funder)

    # Fund with some link
    amount = 2
    fund_with_link(contract_address=contract, amount=Web3.toWei(amount, "ether"))
