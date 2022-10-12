// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TournamentBeacon is Ownable, IBeacon {
    UpgradeableBeacon beacon;
    address private blueprint;

    modifier validAddress(address impl) {
        require(impl != address(0), "Not a valid address");
        _;
    }

    constructor(address _initBlueprint) validAddress(_initBlueprint) {
        beacon = new UpgradeableBeacon(_initBlueprint);
        blueprint = _initBlueprint;
        transferOwnership(tx.origin);
    }

    function update(address newBlueprint)
        external
        onlyOwner
        validAddress(newBlueprint)
    {
        blueprint = newBlueprint;
        beacon.upgradeTo(newBlueprint);
    }

    function implementation() external view override returns (address) {
        return blueprint;
    }
}
