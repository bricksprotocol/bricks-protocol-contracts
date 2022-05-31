import "./Tournament.sol";

contract RecurringTournament is Tournament {
    mapping(uint256 => uint256) cycleBalanceMapping;
    //mapping(uint256 => adress) participantYieldMapping;
    mapping(uint256 => uint256) cycleTotalParticipantsMapping;
    mapping(address => uint256) participantCycleMapping;
    uint256 private cycles;
    bool private hasCreatorInitiatedWithdraw;

    function initialize() external override initializer {
        cycles = 1;
        __Ownable_init();
    }

    function initiateWithdraw() external {
        require(msg.sender == creator, "You are not a creator");
        hasCreatorInitiatedWithdraw = true;
    }

    function joinTournament() public payable override {
        require(
            !hasCreatorInitiatedWithdraw,
            "This is the last tournament.You cannot join now"
        );
        IERC20 ierc20 = IERC20(asset);

        // check if the values match
        uint256 balance = (isNativeAsset)
            ? address(msg.sender).balance
            : ierc20.balanceOf(msg.sender);
        require(
            balance >= tournamentEntryFees,
            "You do not have enough to join this Event"
        );

        require(
            participantCycleMapping[msg.sender] == 0,
            "You have already joined"
        );

        // check if the participant is already registered the event

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
        participantCycleMapping[msg.sender] = cycles;
        cycleTotalParticipantsMapping[cycles]++;
        //participants.push(payable(msg.sender));
        participantWithdrawnStatus[msg.sender] = false;
        emit ParticipantJoined(msg.sender, tournamentEntryFees);
    }

    function withdrawFunds(bytes memory sig) public override {
        require(participantFees[msg.sender], "Participant isn't registered");

        require(
            msg.sender == creator
                ? !hasCreatorWithdrawn
                : !participantWithdrawnStatus[msg.sender],
            "Participant or creator has already withdrawn the share"
        );

        require(
            cycles != participantCycleMapping[msg.sender],
            "You can withdraw at the end of this tournament "
        );

        require(
            verifyMessage(
                Strings.toString(participantRewardMapping[msg.sender]),
                sig
            ),
            "Can't verify identity"
        );
        if (msg.sender == creator && hasCreatorInitiatedWithdraw) {
            withdrawInitialVestedAmount();
            hasCreatorWithdrawn = true;
        }

        if (participantFees[msg.sender]) {
            withdrawFromAave(participantRewardMapping[msg.sender]);
            participantWithdrawnStatus[msg.sender] = true;
            cycleTotalParticipantsMapping[cycles]--;
        }
    }

    function setParticipantRewards(
        uint256[] memory withdrawPercentages,
        address participant
    ) external {
        require(
            msg.sender == 0xAfda3241eAa91e596A6e229b95Bd4eAD7D9EA35F,
            "Not owner"
        );
        uint256 totalWithdrawal = tournamentEntryFees;

        for (uint256 i = 0; i < withdrawPercentages.length; i++) {
            if (i > 0) {
                totalWithdrawal += (cycleBalanceMapping[i + 1] -
                    ((cycleTotalParticipantsMapping[i + 1] *
                        tournamentEntryFees) + initialVestedAmount));
            } else {
                totalWithdrawal +=
                    (cycleBalanceMapping[i + 1] -
                        (cycleTotalParticipantsMapping[i + 1] *
                            tournamentEntryFees)) -
                    (cycleBalanceMapping[i + 1] -
                        (cycleTotalParticipantsMapping[i] *
                            tournamentEntryFees));
            }
        }

        participantRewardMapping[participant] = totalWithdrawal;
    }

    function setCycleBalanceMapping() external {
        require(
            msg.sender == 0xAfda3241eAa91e596A6e229b95Bd4eAD7D9EA35F &&
                !hasCreatorInitiatedWithdraw,
            "Not owner"
        );
        IERC20 ierc20 = IERC20(aAssetAddress);
        cycleBalanceMapping[cycles] = ierc20.balanceOf(address(this));
        cycles++;
        cycleTotalParticipantsMapping[cycles] = cycleTotalParticipantsMapping[
            cycles - 1
        ];
    }
}
