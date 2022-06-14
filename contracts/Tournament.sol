// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./WETHGateway.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/VerifySignature.sol";

contract Tournament is Initializable, OwnableUpgradeable {
    event ParticipantJoined(address indexed participant, uint256 entryFees);
    event Withdraw(address indexed participant, uint256 amount);

    // custom events for testing
    event InitiateWithdraw(address indexed participant, uint256 amount);

    string public tournamentUri;
    uint256 private tournamentStart;
    uint256 private tournamentEnd;
    uint256 private tournamentEntryFees;
    uint256 private initialVestedAmount;
    address payable[] private participants;
    mapping(address => bool) private participantFees;
    address private creator;
    address private asset;
    address private lendingPoolAddress;
    uint256 private protocolFees;
    uint256 private totalWithdrawnAmount = 0;
    address private aAssetAddress;
    bool private isNativeAsset;
    bool private hasCreatorWithdrawn;
    bytes32 public constant ADMIN_ROLE = keccak256("MY_ROLE");
    mapping(address => bool) private participantWithdrawnStatus;
    mapping(address => uint256) private participantRewardMapping;
    bool public isCompleted;
    uint256 private totalPeopleWithdrawn;
    mapping(address => bool) private isRewardMappingSet;
    uint256 private protocolRewards;

    modifier validAddresses(address[5] memory pAddresses) {
        for (uint256 i = 0; i < pAddresses.length; i++) {
            require(pAddresses[i] != address(0), "One of the address is 0");
        }
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == 0xAfda3241eAa91e596A6e229b95Bd4eAD7D9EA35F,
            "Not admin"
        );
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function setParticipantReward(
        uint256 withdrawPercentage,
        address participant
    ) external onlyAdmin {
        isRewardMappingSet[participant] = true;
        participantRewardMapping[participant] = withdrawPercentage;
    }

    function createPool(
        string memory uri,
        uint256 startTime,
        uint256 endTime,
        uint256 entryFees,
        address lendPoolAddress,
        address dataProvider,
        address assetAddress,
        uint256 initialInvestedAmount,
        uint256 fees,
        address sender,
        address aAsset,
        bool nativeAsset
    )
        external
        validAddresses(
            [lendPoolAddress, dataProvider, assetAddress, sender, aAsset]
        )
    {
        require(startTime >= block.timestamp, "Start time has already passed!");

        require(
            endTime > startTime,
            "Tournament should end after start point!"
        );

        require(
            lendPoolAddress != address(0) &&
                dataProvider != address(0) &&
                assetAddress != address(0) &&
                sender != address(0) &&
                aAsset != address(0),
            "One of the adresses is 0"
        );
        tournamentUri = uri;
        tournamentStart = startTime;
        tournamentEnd = endTime;
        tournamentEntryFees = entryFees;
        creator = sender;
        asset = assetAddress;
        lendingPoolAddress = lendPoolAddress;
        protocolFees = fees;
        initialVestedAmount = initialInvestedAmount;
        aAssetAddress = aAsset;
        isNativeAsset = nativeAsset;
    }

    function getTournamentDetails()
        external
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
            tournamentUri,
            tournamentStart,
            tournamentEnd,
            tournamentEntryFees,
            initialVestedAmount,
            asset,
            participants
        );
    }

    function joinTournament() external payable {
        IERC20 ierc20 = IERC20(asset);

        require(
            block.timestamp <= tournamentEnd,
            "Tournament has already ended"
        );

        // check if the values match
        uint256 balance = (isNativeAsset)
            ? address(msg.sender).balance
            : ierc20.balanceOf(msg.sender);
        require(
            balance >= tournamentEntryFees,
            "You do not have enough to join address(this) Event"
        );

        // check if the participant is already registered the event
        require(
            !participantFees[msg.sender],
            "Participant is already registered"
        );

        if (tournamentEntryFees > 0) {
            emit ParticipantJoined(msg.sender, tournamentEntryFees);
            participantFees[msg.sender] = true;
            participants.push(payable(msg.sender));
            participantWithdrawnStatus[msg.sender] = false;
            if (isNativeAsset) {
                WETHGateway gateway = new WETHGateway(asset, address(this));
                bool authorized = gateway.authorizePool(lendingPoolAddress);
                if (authorized) {
                    gateway.depositETH{value: msg.value}(
                        lendingPoolAddress,
                        address(this),
                        0
                    );
                }
            } else {
                require(
                    ierc20.transferFrom(
                        msg.sender,
                        address(this),
                        tournamentEntryFees
                    )
                );
                bool approved = ierc20.approve(
                    lendingPoolAddress,
                    tournamentEntryFees
                );

                if (approved) {
                    IPool(lendingPoolAddress).supply(
                        asset,
                        tournamentEntryFees,
                        address(this),
                        0
                    );
                }
            }
        }
    }

    function withdrawFunds(bytes memory sig) external {
        require(block.timestamp > tournamentEnd, "Tournament hasn't ended");

        //require(isCompleted, "Tournament isn't completed");

        require(
            (msg.sender == creator) ? true : participantFees[msg.sender],
            "Participant or Creator isn't registered"
        );

        require(
            msg.sender == creator
                ? !hasCreatorWithdrawn
                : !participantWithdrawnStatus[msg.sender],
            "Participant or creator has already withdrawn the share"
        );

        require(isRewardMappingSet[msg.sender], "Reward mapping not set");

        require(
            VerifySignature.verifyMessage(
                Strings.toString(participantRewardMapping[msg.sender]),
                sig
            ),
            "Can't verify identity"
        );
        uint256 amountToWithdraw = 0;
        IERC20 ierc20 = IERC20(aAssetAddress);

        if (msg.sender == creator) {
            emit Withdraw(msg.sender, initialVestedAmount);
            emit InitiateWithdraw(msg.sender, initialVestedAmount);
            hasCreatorWithdrawn = true;
            amountToWithdraw += initialVestedAmount;
            totalPeopleWithdrawn += 1;
        }

        if (participantFees[msg.sender]) {
            participantWithdrawnStatus[msg.sender] = true;
            amountToWithdraw += computeEntryFeesWithRewards(
                participantRewardMapping[msg.sender]
            );
            totalPeopleWithdrawn += 1;
        }

        //withdrawEntryFeesWithRewards(participantRewardMapping[msg.sender]);

        //withdrawInitialVestedAmount();

        if (amountToWithdraw > ierc20.balanceOf(address(this))) {
            amountToWithdraw = ierc20.balanceOf(address(this));
        }
        totalWithdrawnAmount += amountToWithdraw;
        emit Withdraw(msg.sender, amountToWithdraw);
        emit InitiateWithdraw(msg.sender, amountToWithdraw);

        if (amountToWithdraw > 0) {
            withdrawFromAave(amountToWithdraw);
        }
    }

    function withdrawProtocolFees() external onlyAdmin {
        if (protocolRewards > 0) {
            uint256 amountToWithdraw = protocolRewards;
            protocolRewards = 0;
            withdrawFromAave(amountToWithdraw);
        }
    }

    function withdrawAdminFunds() external onlyAdmin {
        require(
            totalPeopleWithdrawn >=
                participants.length + ((initialVestedAmount > 0) ? 1 : 0),
            "Everyone hasnt'withdrawn their yield"
        );
        IERC20 ierc20 = IERC20(aAssetAddress);
        withdrawFromAave((ierc20.balanceOf(address(this))));
    }

    // function withdrawInitialVestedAmount() private {
    //     if (msg.sender == creator && initialVestedAmount > 0) {
    //         totalWithdrawnAmount += initialVestedAmount;
    //         withdrawFromAave(initialVestedAmount);
    //     }
    // }

    function computeEntryFeesWithRewards(uint256 rewardsPercentage)
        public
        returns (uint256)
    {
        uint256 amountToWithdraw = 0;
        if (tournamentEntryFees > 0) {
            IERC20 ierc20 = IERC20(aAssetAddress);
            uint256 totalParticipantFees = tournamentEntryFees *
                participants.length;
            uint256 rewards = 0;
            if (
                (ierc20.balanceOf(address(this)) + totalWithdrawnAmount) >
                (totalParticipantFees + initialVestedAmount)
            ) {
                rewards =
                    (ierc20.balanceOf(address(this)) + totalWithdrawnAmount) -
                    (totalParticipantFees + initialVestedAmount);
            }
            protocolRewards += ((rewardsPercentage * rewards * protocolFees) /
                10**6);
            amountToWithdraw =
                tournamentEntryFees +
                ((rewardsPercentage * rewards * (100 - protocolFees)) / 10**6);
            // totalWithdrawnAmount += amountToWithdraw;
            // emit Withdraw(msg.sender, amountToWithdraw);
            // emit InitiateWithdraw(msg.sender, amountToWithdraw);
            // withdrawFromAave(amountToWithdraw);
        }

        return amountToWithdraw;
    }

    function withdrawFromAave(uint256 amountToWithdraw) private {
        if (isNativeAsset) {
            IAToken aWETH = IAToken(aAssetAddress);
            WETHGateway gateway = new WETHGateway(asset, address(this));
            bool authorized = gateway.authorizePool(lendingPoolAddress);
            bool approved = aWETH.approve(address(gateway), amountToWithdraw);
            if (approved && authorized) {
                gateway.withdrawETH(
                    lendingPoolAddress,
                    amountToWithdraw,
                    msg.sender
                );
            }
        } else {
            uint256 amountWithdrawn = IPool(lendingPoolAddress).withdraw(
                address(asset),
                amountToWithdraw,
                msg.sender
            );
        }
    }

    function hasUserWithdrawn() external view returns (bool) {
        if (msg.sender == creator) {
            return hasCreatorWithdrawn;
        }

        return participantWithdrawnStatus[msg.sender];
    }

    function setCompletionStatus() external onlyAdmin {
        isCompleted = true;
    }

    function totalBalance() external view returns (uint256) {
        IERC20 ierc20 = IERC20(aAssetAddress);
        return ierc20.balanceOf(address(this));
    }

    function totalWithdrawnAmountFn() external view returns (uint256) {
        return totalWithdrawnAmount;
    }

    function participantRewardMappingFn() external view returns (uint256) {
        return participantRewardMapping[msg.sender];
    }

    function updateProtocolFees(uint256 updatedProtocolFees)
        external
        onlyAdmin
    {
        protocolFees = updatedProtocolFees;
    }
}
