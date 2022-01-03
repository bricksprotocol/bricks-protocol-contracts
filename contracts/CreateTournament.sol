// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "../interfaces/IWETHGateway.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IERC20.sol";

contract CreateTournament is Ownable {
    string public tournamentURI;
    uint256 public tournamentStart;
    uint256 public tournamentEnd;
    uint256 public tournamentEntryFees;
    uint256 public initialVestedAmount;
    address payable[] public participants;
    mapping(address => bool) public participantFees;
    address public creator;
    address internal asset;
    address internal lending_pool_address;

    // @dev tournamentURI will contain all the details pertaining to an tournament
    // {"name": "tournament_name", "description" : "tournament_description", "trading_assets": [], "image": "image_url"}
    function createPool(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _lending_pool_address,
        address _asset,
        uint256 _initial_invested_amount,
        address _sender
    ) public {
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
        creator = _sender;
        asset = _asset;
        lending_pool_address = _lending_pool_address;
        initialVestedAmount = _initial_invested_amount;
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

    function joinTournament() public {
        // check if the values match
        IERC20 ierc20 = IERC20(asset);
        uint256 balance = ierc20.balanceOf(msg.sender);
        require(
            balance >= tournamentEntryFees,
            "You do not have enough to join this Event"
        );
        // check if the participant is already registered the event
        require(
            participantFees[msg.sender] != true,
            "The participant is already registered"
        );

        if (tournamentEntryFees != 0) {
            require(
                ierc20.transferFrom(
                    msg.sender,
                    address(this),
                    tournamentEntryFees
                )
            );
            ierc20.approve(lending_pool_address, tournamentEntryFees);
            ILendingPool(lending_pool_address).deposit(
                asset,
                tournamentEntryFees,
                address(this),
                0
            );
        }
        participantFees[msg.sender] = true;
        participants.push(payable(msg.sender));
    }

    // dummy funtion to withdraw funds, not to be used for production
    function withdrawFunds(address _address, address _aave_asset) public {
        IERC20 ierc20 = IERC20(_aave_asset);
        uint256 balance = ierc20.balanceOf(address(this));
        ILendingPool(lending_pool_address).withdraw(asset, balance, _address);
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function getCreator() public view returns (address) {
        return creator;
    }
}
