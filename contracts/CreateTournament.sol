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
    address asset;
    address lending_pool_address;

    // @dev tournamentURI will contain all the details pertaining to an tournament
    // {"name": "tournament_name", "description" : "tournament_description", "trading_assets": [], "image": "image_url"}
    constructor(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _lending_pool_address,
        address _asset,
        uint256 _initial_invested_amount,
        address _sender
    ) {
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
        if (_initial_invested_amount != 0) {
            // IERC20(asset).transferFrom(
            //     creator,
            //     address(this),
            //     _initial_invested_amount
            // );
            // IERC20(asset).approve(
            //     lending_pool_address,
            //     _initial_invested_amount
            // );
            ILendingPool(lending_pool_address).deposit(
                asset,
                _initial_invested_amount,
                address(this),
                0
            );
        }
        // if (msg.value != 0) {
        //     address lendingPool = ILendingPoolAddressesProvider(
        //         0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        //     ).getLendingPool();
        //     ILendingPool(lendingPool).deposit(
        //         asset,
        //         msg.value,
        //         address(this),
        //         0
        //     );
        // }
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
        // if (msg.value != 0) {
        //     address lendingPool = ILendingPoolAddressesProvider(
        //         0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        //     ).getLendingPool();
        //     IWETHGateway(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04).depositETH{
        //         value: msg.value
        //     }(lendingPool, address(this), 0);
        // }
        if (msg.value != 0) {
            ILendingPool(lending_pool_address).deposit(
                asset,
                msg.value,
                address(this),
                0
            );
        }
        participantFees[msg.sender] = true;
        participants.push(payable(msg.sender));
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function getCreator() public view returns (address) {
        return creator;
    }
}
