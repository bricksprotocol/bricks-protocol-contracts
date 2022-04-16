// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
//import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/IWethGateway.sol";
//import "./interfaces/IPool.sol";
import "./aave/v2/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "./interfaces/IERC20.sol";

contract Tournament is Ownable {
    enum ParticipantType {
        CREATOR,
        PARTICIPANT,
        BOTH
    }
    event ParticipantJoined(address indexed participant, uint256 entryFees);
    event withdraw(address indexed participant, uint256 amount);

    // custom events for testing
    event InitiateWithdraw(address indexed participant, uint256 amount);

    //using Chainlink for Chainlink.Request;

    string public tournamentURI;
    uint256 public tournamentStart;
    uint256 public tournamentEnd;
    uint256 public tournamentEntryFees;
    uint256 public initialVestedAmount;
    bool internal initialVestedRefund = false;
    address payable[] public participants;
    mapping(address => bool) public participantFees;
    address public creator;
    address public asset;
    address public lending_pool_address;
    mapping(bytes32 => address) requestMapping;
    address dataProvider;
    uint256 public protocolFees;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address public linkTokenAddress;
    uint256 totalWithdrawnAmount = 0;

    // custom variables for testing only
    uint256 public fraction;
    string public data;
    uint256 private finalAmount;
    mapping(address => bool) public participantWithdrawnStatus;

    // // initializing oracle, jobid and fee for the required network
    // constructor(
    //     address _oracle,
    //     bytes32 _jobId,
    //     uint256 _fee //address _linkTokenAddress
    // ) {
    //     // setPublicChainlinkToken();
    //     oracle = _oracle;
    //     jobId = _jobId;
    //     fee = _fee;
    //     //linkTokenAddress = _linkTokenAddress;
    //     //setChainlinkToken(_linkTokenAddress);
    //     //setChainlinkOracle(_oracle);
    // }

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
        uint256 _protocolFees,
        address _sender
    ) public {
        // require(
        //     _tournamentStart >= block.timestamp,
        //     "Start time has already passed!"
        // );
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
        protocolFees = _protocolFees;
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
        ERC20 ierc20 = ERC20(asset);
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
        participantWithdrawnStatus[msg.sender] = false;
        emit ParticipantJoined(msg.sender, tournamentEntryFees);
    }

    // dummy funtion to withdraw funds, not to be used for production
    function withdrawFunds(uint256 withdrawPercentage) public {
        // IERC20 ierc20 = IERC20(_aave_asset);
        // uint256 balance = ierc20.balanceOf(address(this));
        // ILendingPool(lending_pool_address).withdraw(asset, balance, _address);
        // todo : check if the withdrawer is either creator or participant
        // todo : check if the event has ended
        // todo : check if creator is zero
        // todo : check if entry fees is zero
        // todo : check if creator has participated
        // todo : 10% protocol fees to be withdrawn

        // if (initialVestedAmount == 0 && tournamentEntryFees == 0) {
        //     // initial invested amount as well as entry fees both are zero
        //     // There is no need to withdraw any amount as aave has not been used
        //     // Instead change the flags for withdrawal
        // } else if (initialVestedAmount == 0 && participantFees[msg.sender]) {
        //     // only initial invested amount is zero
        //     withdrawEntryFees();
        // } else if (tournamentEntryFees == 0) {
        //     // only tournament entry fees is zero
        //     withdrawInitialVestedAmount();
        // } else {
        //     // Neither initial invested amount or tournament fee is zero
        //     if (msg.sender == creator && participantFees[msg.sender]) {
        //         // msg.sender is a creator as well as a participant
        //         withdrawInitialVestedAmount();
        //         withdrawEntryFees();
        //     } else if (msg.sender == creator) {
        //         // msg.sender is only creator
        //         withdrawInitialVestedAmount();
        //     } else if (participantFees[msg.sender]) {
        //         // msg.sender is a participant
        //         withdrawEntryFees();
        //     }
        // }
        // withdrawEntryFees();

        if (msg.sender == creator) {
            withdrawInitialVestedAmount();
        }

        if (participantFees[msg.sender]) {
            withdrawEntryFeesWithRewards(withdrawPercentage);
        }
    }

    function getWithdrawalStatus() public view returns (bool) {
        return participantFees[msg.sender];
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function getCreator() public view returns (address) {
        return creator;
    }

    function withdrawInitialVestedAmount() internal {
        //ERC20 ierc20 = ERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);

        if (
            msg.sender == creator &&
            !initialVestedRefund &&
            initialVestedAmount > 0
        ) {
            //ierc20.approve(msg.sender, initialVestedAmount);
            ILendingPool(lending_pool_address).withdraw(
                address(asset),
                initialVestedAmount,
                msg.sender
            );
            initialVestedRefund = true;
            totalWithdrawnAmount += initialVestedAmount;
            emit withdraw(msg.sender, initialVestedAmount);
            emit InitiateWithdraw(msg.sender, initialVestedAmount);
        }
    }

    // function withdrawEntryFees() internal returns (bytes32 requestId) {
    //     emit InitiateWithdraw(msg.sender, 1);
    //     Chainlink.Request memory request = buildChainlinkRequest(
    //         jobId,
    //         address(this),
    //         this.fulfill.selector
    //     );

    //     // Set the URL to perform the GET request on
    //     // request.add(
    //     //     "get",
    //     //     string(
    //     //         abi.encodePacked(
    //     //             "https://testapi.bricksprotocol.com/api/v1/contracts/fraction?user_address=",
    //     //             toAsciiString(msg.sender),
    //     //             "&event_address=",
    //     //             toAsciiString(address(this))
    //     //         )
    //     //     )
    //     // );

    //     // request.add("path", "fractional_split");

    //     // Test function
    //     request.add(
    //         "get",
    //         "https://ipfs.io/ipfs/QmfDiv81deQNEGGPKPWfEmbAuu9186v3dsVBSfuLSS8iBe"
    //     );

    //     request.add("path", "value");

    //     // Multiply the result by 1000000000000000000 to remove decimals
    //     // int256 timesAmount = 10**8;
    //     // request.addInt("times", timesAmount);

    //     // Sends the request
    //     // bytes32 requestID = sendChainlinkRequestTo(oracle, request, fee);
    //     bytes32 requestID = sendOperatorRequest(request, fee);
    //     requestMapping[requestID] = msg.sender;
    //     fraction = 1;
    //     data = "1";
    // }

    function withdrawEntryFeesWithRewards(uint256 rewardsPercentage) public {
        if (tournamentEntryFees > 0) {
            ERC20 ierc20 = ERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);
            uint256 totalParticipantFees = tournamentEntryFees *
                participants.length;
            uint256 rewards = (ierc20.balanceOf(address(this)) +
                totalWithdrawnAmount) -
                (totalParticipantFees + initialVestedAmount);
            uint256 amountToWithdraw = tournamentEntryFees +
                ((rewardsPercentage * rewards) / 100);
            ILendingPool(lending_pool_address).withdraw(
                address(asset),
                amountToWithdraw,
                msg.sender
            );
            totalWithdrawnAmount += amountToWithdraw;
            emit withdraw(msg.sender, amountToWithdraw);
            emit InitiateWithdraw(msg.sender, amountToWithdraw);
        }
    }

    /**
     * Receive the response in the form of uint256
     */
    // function fulfill(bytes32 _requestId, bytes memory _data)
    //     public
    //     recordChainlinkFulfillment(_requestId)
    // {
    //     // address sender = requestMapping[_requestId];
    //     // IProtocolDataProvider provider = IProtocolDataProvider(dataProvider);
    //     // uint256 balance;
    //     // (balance, , , , , , , , ) = provider.getUserReserveData(
    //     //     asset,
    //     //     address(this)
    //     // );
    //     // // IERC20 ierc20 = IERC20(aave_asset_address);
    //     // // uint256 balance = ierc20.balanceOf(address(this));
    //     // uint256 poolinterest = balance -
    //     //     initialVestedAmount -
    //     //     participants.length *
    //     //     tournamentEntryFees;
    //     // uint256 withdrawAmount = (poolinterest * _fraction) /
    //     //     uint256(10**8) +
    //     //     tournamentEntryFees;
    //     // // uint256 withdrawAmount = poolinterest * (_fraction / uint256(10**8));
    //     // ILendingPool(lending_pool_address).withdraw(
    //     //     asset,
    //     //     withdrawAmount,
    //     //     sender
    //     // );
    //     // participantFees[sender] = false;
    //     data = string(_data);
    //     // emit withdraw(sender, withdrawAmount);
    //     // emit InitiateWithdraw(sender, withdrawAmount);
    // }

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

    function getData() public view returns (string memory) {
        return data;
    }
}
