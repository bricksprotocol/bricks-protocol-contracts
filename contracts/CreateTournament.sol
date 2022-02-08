// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../interfaces/IProtocolDataProvider.sol";
// import "../interfaces/IWETHGateway.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IERC20.sol";

contract CreateTournament is Ownable, ChainlinkClient {
    event ParticipantJoined(address indexed participant, uint256 entryFees);
    event withdraw(address indexed participant, uint256 amount);

    using Chainlink for Chainlink.Request;

    string public tournamentURI;
    uint256 public tournamentStart;
    uint256 public tournamentEnd;
    uint256 public tournamentEntryFees;
    uint256 public initialVestedAmount;
    address payable[] public participants;
    mapping(address => bool) public participantFees;
    address public creator;
    address public asset;
    address internal lending_pool_address;
    mapping(bytes32 => address) requestMapping;
    address dataProvider;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // custom variables for testing only
    uint256 public fraction;

    // initializing oracle, jobid and fee for the required network
    constructor(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    // @dev tournamentURI will contain all the details pertaining to an tournament
    // {"name": "tournament_name", "description" : "tournament_description", "trading_assets": [], "image": "image_url"}
    function createPool(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _lending_pool_address,
        address _dataProvider,
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
        dataProvider = _dataProvider;
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
            address,
            address payable[] memory
        )
    {
        return (
            getCreator(),
            tournamentURI,
            tournamentStart,
            tournamentEnd,
            tournamentEntryFees,
            initialVestedAmount,
            asset,
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
        emit ParticipantJoined(msg.sender, tournamentEntryFees);
    }

    // dummy funtion to withdraw funds, not to be used for production
    function withdrawFunds() public {
        // IERC20 ierc20 = IERC20(_aave_asset);
        // uint256 balance = ierc20.balanceOf(address(this));
        // ILendingPool(lending_pool_address).withdraw(asset, balance, _address);
        // todo : check if the withdrawer is either creator or participant
        // todo : check if the event has ended
        // todo : check if creator is zero
        // todo: check if entry fees is zero
        // todo: check if creator has participated
        requestData();
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function getCreator() public view returns (address) {
        return creator;
    }

    function requestData() internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        request.add(
            "get",
            string(
                abi.encodePacked(
                    "https://testapi.bricksprotocol.com/api/v1/contracts/fraction?user_address=",
                    toAsciiString(msg.sender),
                    "&event_address=",
                    toAsciiString(address(this))
                )
            )
        );

        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "fractional_split");

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**8;
        request.addInt("times", timesAmount);

        // Sends the request
        bytes32 requestID = sendChainlinkRequestTo(oracle, request, fee);
        requestMapping[requestID] = msg.sender;
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _fraction)
        public
        recordChainlinkFulfillment(_requestId)
    {
        address sender = requestMapping[_requestId];
        IProtocolDataProvider provider = IProtocolDataProvider(dataProvider);
        uint256 balance;
        (balance, , , , , , , , ) = provider.getUserReserveData(
            asset,
            address(this)
        );
        // IERC20 ierc20 = IERC20(aave_asset_address);
        // uint256 balance = ierc20.balanceOf(address(this));
        uint256 poolinterest = balance -
            initialVestedAmount -
            participants.length *
            tournamentEntryFees;
        uint256 withdrawAmount = (poolinterest * _fraction) /
            uint256(10**8) +
            tournamentEntryFees;
        // uint256 withdrawAmount = poolinterest * (_fraction / uint256(10**8));
        ILendingPool(lending_pool_address).withdraw(
            asset,
            withdrawAmount,
            sender
        );
        emit withdraw(sender, withdrawAmount);
        fraction = balance;
    }

    // functions that could be in a library
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // custom functions for testing

    function getFraction() public view returns (uint256) {
        return fraction;
    }
}
