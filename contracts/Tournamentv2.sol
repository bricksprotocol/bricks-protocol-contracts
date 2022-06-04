//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Tournament.sol";

contract Tournamentv2 is Tournament {
    function upgradeUri(string memory uri) public {
        tournamentURI = uri;
    }

    function withdraw2(bytes memory sig) public {
        withdrawFunds(sig);
    }
}
