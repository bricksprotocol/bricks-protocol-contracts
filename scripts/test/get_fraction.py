from brownie import CreateTournament, interface, Contract
from scripts.helpful_scripts import get_account


def get_fraction(contract_address):
    contract = Contract.from_abi(
        CreateTournament._name,
        contract_address,
        CreateTournament.abi,
    )
    # contract = CreateTournament(contract_address)
    fraction = contract.getFraction()
    print(f"fraction is {fraction}")


def get_data(contract_address):
    contract = Contract.from_abi(
        CreateTournament._name,
        contract_address,
        CreateTournament.abi,
    )
    # contract = CreateTournament(contract_address)
    fraction = contract.getData()
    print(f"data is {fraction}")


def main():
    # enter the tournament contract address here
    contract_address = "0xDaFdA3A53A7E539AF4225B65A03233cC877A95B7"
    get_fraction(contract_address)
    get_data(contract_address)
