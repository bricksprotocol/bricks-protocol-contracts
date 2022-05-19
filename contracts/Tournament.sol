// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./WETHGateway.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Tournament is Initializable, OwnableUpgradeable {
    using ECDSA for bytes32;

    // enum ParticipantType {
    //     CREATOR,
    //     PARTICIPANT,
    //     BOTH
    // }
    event ParticipantJoined(address indexed participant, uint256 entryFees);
    event withdraw(address indexed participant, uint256 amount);

    // custom events for testing
    event InitiateWithdraw(address indexed participant, uint256 amount);

    //using Chainlink for Chainlink.Request;

    string public tournamentURI;
    uint256 private tournamentStart;
    uint256 private tournamentEnd;
    uint256 private tournamentEntryFees;
    uint256 private initialVestedAmount;
    //bool internal initialVestedRefund = false;
    address payable[] public participants;
    mapping(address => bool) private participantFees;
    struct Creator {
        address creator;
        bool hasCreatorWithdrawn;
    }
    address private creator;
    address private asset;
    address private lending_pool_address;
    //mapping(bytes32 => address) requestMapping;
    uint256 public protocolFees;
    //address private oracle;
    //bytes32 private jobId;
    //uint256 private fee;
    // address public linkTokenAddress;
    uint256 totalWithdrawnAmount = 0;
    // address private verificationAddress;
    address private aAssetAddress;
    bool private isNativeAsset;
    bool private hasCreatorWithdrawn;
    uint256 public _allowance;
    bytes32 public constant ADMIN_ROLE = keccak256("MY_ROLE");
    // custom variables for testing only
    // uint256 public fraction;
    // string public data;
    //  uint256 private finalAmount;
    mapping(address => bool) public participantWithdrawnStatus;
    mapping(address => uint256) private participantRewardMapping;

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

    // constructor() {
    //     //  verificationAddress = _verificationAddress;
    // }

    // @dev tournamentURI will contain all the details pertaining to an tournament
    // {"name": "tournament_name", "description" : "tournament_description", "trading_assets": [], "image": "image_url"}

    function initialize() external initializer {
        __Ownable_init();
    }

    function setParticipantReward(
        uint256 withdrawPercentage,
        address participant
    ) external {
        require(
            msg.sender == 0xAfda3241eAa91e596A6e229b95Bd4eAD7D9EA35F,
            "Not owner"
        );
        participantRewardMapping[participant] = withdrawPercentage;
    }

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
        address _sender,
        address _aAssetAddress,
        bool _isNativeAsset
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
        protocolFees = _protocolFees;
        initialVestedAmount = _initial_invested_amount;
        aAssetAddress = _aAssetAddress;
        isNativeAsset = _isNativeAsset;
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
            creator,
            tournamentURI,
            tournamentStart,
            tournamentEnd,
            tournamentEntryFees,
            initialVestedAmount,
            asset,
            participants
        );
    }

    function joinTournament() public payable {
        IERC20 ierc20 = IERC20(asset);

        // check if the values match
        uint256 balance = (isNativeAsset)
            ? address(msg.sender).balance
            : ierc20.balanceOf(msg.sender);
        require(
            balance >= tournamentEntryFees,
            "You do not have enough to join this Event"
        );
        // check if the participant is already registered the event
        require(
            participantFees[msg.sender] != true,
            "Participant is already registered"
        );

        if (tournamentEntryFees != 0) {
            if (isNativeAsset) {
                WETHGateway gateway = new WETHGateway(asset, address(this));
                gateway.authorizePool(lending_pool_address);
                gateway.depositETH{value: msg.value}(
                    lending_pool_address,
                    address(this),
                    0
                );
            } else {
                require(
                    ierc20.transferFrom(
                        msg.sender,
                        address(this),
                        tournamentEntryFees
                    )
                );
                ierc20.approve(lending_pool_address, tournamentEntryFees);
                IPool(lending_pool_address).supply(
                    asset,
                    tournamentEntryFees,
                    address(this),
                    0
                );
            }
        }
        participantFees[msg.sender] = true;
        participants.push(payable(msg.sender));
        participantWithdrawnStatus[msg.sender] = false;
        emit ParticipantJoined(msg.sender, tournamentEntryFees);
    }

    function withdrawFunds(bytes memory sig) public {
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

        //Verify verify = Verify(verificationAddress);
        require(block.timestamp > tournamentEnd, "Tournament hasn't ended");
        require(
            msg.sender == creator
                ? !hasCreatorWithdrawn
                : !participantWithdrawnStatus[msg.sender],
            "Participant or creator has already withdrawn the share"
        );
        require(
            verifyMessage(
                Strings.toString(participantRewardMapping[msg.sender]),
                sig
            ),
            "Can't verify identity"
        );
        if (msg.sender == creator) {
            withdrawInitialVestedAmount();
            hasCreatorWithdrawn = true;
        }

        if (participantFees[msg.sender]) {
            withdrawEntryFeesWithRewards(participantRewardMapping[msg.sender]);
            participantWithdrawnStatus[msg.sender] = true;
        }
    }

    // function getWithdrawalStatus() public view returns (bool) {
    //     return participantFees[msg.sender];
    // }

    // function getParticipants() public view returns (address payable[] memory) {
    //     return participants;
    // }

    // function getCreator() public view returns (address) {
    //     return creator;
    // }

    function withdrawInitialVestedAmount() private {
        //ERC20 ierc20 = ERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);

        if (msg.sender == creator && initialVestedAmount > 0) {
            withdrawFromAave(initialVestedAmount);
            totalWithdrawnAmount += initialVestedAmount;
            emit withdraw(msg.sender, initialVestedAmount);
            emit InitiateWithdraw(msg.sender, initialVestedAmount);
        }
    }

    function withdrawEntryFeesWithRewards(uint256 rewardsPercentage) private {
        if (tournamentEntryFees > 0) {
            IERC20 ierc20 = IERC20(aAssetAddress);
            uint256 totalParticipantFees = tournamentEntryFees *
                participants.length;
            uint256 rewards = (ierc20.balanceOf(address(this)) +
                totalWithdrawnAmount) -
                (totalParticipantFees + initialVestedAmount);
            uint256 amountToWithdraw = tournamentEntryFees +
                ((rewardsPercentage * rewards) / 10**4);
            withdrawFromAave(amountToWithdraw);
            totalWithdrawnAmount += amountToWithdraw;
            emit withdraw(msg.sender, amountToWithdraw);
            emit InitiateWithdraw(msg.sender, amountToWithdraw);
        }
    }

    function withdrawFromAave(uint256 amountToWithdraw) private {
        if (isNativeAsset) {
            IAToken aWETH = IAToken(aAssetAddress);
            IERC20 ierc20 = IERC20(asset);

            WETHGateway gateway = new WETHGateway(asset, address(this));
            gateway.authorizePool(lending_pool_address);
            aWETH.approve(address(gateway), amountToWithdraw);
            gateway.withdrawETH(
                lending_pool_address,
                amountToWithdraw,
                msg.sender
            );
        } else {
            IPool(lending_pool_address).withdraw(
                address(asset),
                amountToWithdraw,
                msg.sender
            );
        }
    }

    function verifyMessage(string memory message, bytes memory signature)
        public
        view
        returns (bool)
    {
        //hash the plain text message
        bytes32 messagehash = keccak256(bytes(message));

        address signeraddress = messagehash.toEthSignedMessageHash().recover(
            signature
        );

        if (msg.sender == signeraddress) {
            //The message is authentic
            return true;
        } else {
            //msg.sender didnt sign this message.
            return false;
        }
    }
}
