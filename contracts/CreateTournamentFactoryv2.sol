//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreateTournamentFactory.sol";

contract CreateTournamentFactoryv2 is CreateTournamentFactory {
    function upgradeLendingAddress(address updatedAddress) public {
        lendingPoolAddress = updatedAddress;
    }
}
