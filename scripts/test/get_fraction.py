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
    contract_address = "0x8b2B2b7F9413bAa865aB19b1096CfD4202345D37"
    get_fraction(contract_address)
