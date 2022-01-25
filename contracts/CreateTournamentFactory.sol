// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./CreateTournament.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILendingPool.sol";

contract CreateTournamentFactory {
    CreateTournament[] public tournamentsArray;
    mapping(address => bool) tournamentsMapping;
    event tournamentCreated(address tournamentAddress);
    IERC20 ierc20;
    address linkTokenAddress = 0xa36085F69e2889c224210F603D836748e7dC0088;
    uint256 linkFundValue = 0.1 * 10**18;

    function createTournamentPool(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _lending_pool_address,
        address _asset,
        uint256 _initial_invested_amount
    ) public {
        ierc20 = IERC20(_asset);
        CreateTournament createTournament = new CreateTournament();
        createTournament.createPool({
            _tournamentURI: _tournamentURI,
            _tournamentStart: _tournamentStart,
            _tournamentEnd: _tournamentEnd,
            _tournamentEntryFees: _tournamentEntryFees,
            _lending_pool_address: _lending_pool_address,
            _asset: _asset,
            _initial_invested_amount: _initial_invested_amount,
            _sender: msg.sender
        });
        if (_initial_invested_amount != 0) {
            require(
                ierc20.transferFrom(
                    msg.sender,
                    address(this),
                    _initial_invested_amount
                )
            );
            ierc20.approve(_lending_pool_address, _initial_invested_amount);
            ILendingPool(_lending_pool_address).deposit(
                _asset,
                _initial_invested_amount,
                address(createTournament),
                0
            );
        }
        tournamentsArray.push(createTournament);
        tournamentsMapping[address(createTournament)] = true;
        IERC20 linkTokenContract = IERC20(linkTokenAddress);
        linkTokenContract.approve(address(this), linkFundValue);
        linkTokenContract.transferFrom(
            address(this),
            address(createTournament),
            linkFundValue
        );
        emit tournamentCreated(address(createTournament));
    }

    function getTournamentDetails(uint256 _index)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address payable[] memory
        )
    {
        return tournamentsArray[_index].getTournamentDetails();
    }

    function getTournamentDetailsByAddress(address _tournament)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address payable[] memory
        )
    {
        require(
            tournamentsMapping[_tournament],
            "This tournament contract does not exists"
        );
        return CreateTournament(_tournament).getTournamentDetails();
    }
}
