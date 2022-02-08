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


def main():
    # enter the tournament contract address here
    contract_address = "0x2641E1CBfE31806d2cd39Edd1568528AD30184c0"
    get_fraction(contract_address)
