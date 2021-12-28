// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CreateTournament is Ownable {
    string public tournamentURI;
    uint256 public tournamentStart;
    uint256 public tournamentEnd;
    uint256 public tournamentEntryFees;
    uint256 public initialVestedAmount;
    address payable[] public participants;
    mapping(address => bool) public participantFees;

    // @dev tournamentURI will contain all the details pertaining to an tournament
    // {"name": "tournament_name", "description" : "tournament_description", "trading_assets": [], "image": "image_url"}
    constructor(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address payable _sender
    ) payable {
        require(
            _tournamentStart >= block.timestamp,
            "Start time has already passed!"
        );
        require(
            _tournamentEnd > _tournamentStart,
            "Tournament should end after start point!"
        );
        tournamentURI = _tournamentURI;
        tournamentStart = _tournamentStart;
        tournamentEnd = _tournamentEnd;
        tournamentEntryFees = _tournamentEntryFees;
        transferOwnership(_sender);
        initialVestedAmount = msg.value;
    }

    // function changeTournamentURI(string memory _tournamentURI)
    //     public
    //     onlyOwner
    // {
    //     tournamentURI = _tournamentURI;
    // }

    function getTournamentDetails()
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
        return (
            owner(),
            tournamentURI,
            tournamentStart,
            tournamentEnd,
            tournamentEntryFees,
            initialVestedAmount,
            getParticipants()
        );
    }

    function joinTournament() public payable {
        // check if the values match
        require(
            msg.value == tournamentEntryFees,
            "Fees and value do not match"
        );
        // check if the participant is already registered the event
        require(
            participantFees[msg.sender] != true,
            "The participant is already registered"
        );
        participantFees[msg.sender] = true;
        participants.push(payable(msg.sender));
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }
}
