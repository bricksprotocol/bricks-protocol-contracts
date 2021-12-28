// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./CreateTournament.sol";

contract CreateTournamentFactory {
    CreateTournament[] public tournamentsArray;
    mapping(address => bool) tournamentsMapping;
    event tournamentCreated(address tournamentAddress);

    function createTournamentContract(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees
    ) public payable {
        CreateTournament createTournament = (new CreateTournament){
            value: msg.value
        }({
            _tournamentURI: _tournamentURI,
            _tournamentStart: _tournamentStart,
            _tournamentEnd: _tournamentEnd,
            _tournamentEntryFees: _tournamentEntryFees,
            _sender: payable(msg.sender)
        });
        tournamentsArray.push(createTournament);
        tournamentsMapping[address(createTournament)] = true;
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
