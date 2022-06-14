// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Tournament.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "./TournamentBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract CreateTournamentFactory is OwnableUpgradeable {
    BeaconProxy[] public tournamentsArray;
    mapping(address => bool) tournamentsMapping;
    event TournamentCreated(address tournamentAddress);
    event ProtocolFeesUpdated(uint256 protocolFees);
    IERC20 ierc20;
    address lendingPoolAddressProvider;
    address public lendingPoolAddress;
    address dataProvider;
    uint256 public protocolFees; // 10% - 1000 (support upto 2 decimal places)
    address private implementationContract;
    TournamentBeacon public tournamentBeacon;

    modifier validAddress(address impl) {
        require(impl != address(0), "Address is 0");
        _;
    }

    function initialize(address impl) external initializer validAddress(impl) {
        tournamentBeacon = new TournamentBeacon(impl);
        implementationContract = impl;
        __Ownable_init();
    }

    function setProtocolFees(uint256 _protocolFees) external onlyOwner {
        emit ProtocolFeesUpdated(_protocolFees);
        protocolFees = _protocolFees;
    }

    function setLendingPoolAddressProvider(address _lendingPoolAddressProvider)
        external
        onlyOwner
        validAddress(_lendingPoolAddressProvider)
    {
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        lendingPoolAddress = IPoolAddressesProvider(lendingPoolAddressProvider)
            .getPool();
        require(lendingPoolAddress != address(0), "Lending Pool Address is 0");
        dataProvider = IPoolAddressesProvider(lendingPoolAddressProvider)
            .getPoolDataProvider();
        require(dataProvider != address(0), "Data Provider Address is 0");
    }

    function getLendingPoolAddressProvider()
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        return (lendingPoolAddressProvider, lendingPoolAddress, dataProvider);
    }

    function createTournamentPool(
        string memory tournamentUri,
        uint256 tournamentStart,
        uint256 tournamentEnd,
        uint256 tournamentEntryFees,
        address asset,
        uint256 initialInvestedAmount,
        address aAssetAddress,
        bool isNativeAsset
    ) external payable {
        ierc20 = IERC20(asset);
        BeaconProxy tournamentProxy = new BeaconProxy(
            address(tournamentBeacon),
            abi.encodeWithSelector(Tournament(address(0)).initialize.selector)
        );
        tournamentsArray.push(tournamentProxy);
        tournamentsMapping[address(tournamentProxy)] = true;
        emit TournamentCreated(address(tournamentProxy));
        WETHGateway gateway = new WETHGateway(asset, address(this));
        Tournament(address(tournamentProxy)).createPool({
            uri: tournamentUri,
            startTime: tournamentStart,
            endTime: tournamentEnd,
            entryFees: tournamentEntryFees,
            lendPoolAddress: lendingPoolAddress,
            dataProvider: dataProvider,
            assetAddress: asset,
            initialInvestedAmount: initialInvestedAmount,
            fees: protocolFees,
            sender: msg.sender,
            aAsset: aAssetAddress,
            nativeAsset: isNativeAsset
        });
        if (initialInvestedAmount > 0) {
            if (isNativeAsset) {
                bool approved = gateway.authorizePool(lendingPoolAddress);

                if (approved) {
                    gateway.depositETH{value: msg.value}(
                        lendingPoolAddress,
                        address(tournamentProxy),
                        0
                    );
                }
            } else {
                require(
                    ierc20.transferFrom(
                        msg.sender,
                        address(this),
                        initialInvestedAmount
                    ),
                    "Transfer failed!"
                );
                bool approved = ierc20.approve(
                    lendingPoolAddress,
                    initialInvestedAmount
                );
                if (approved) {
                    IPool(lendingPoolAddress).supply(
                        asset,
                        initialInvestedAmount,
                        address(tournamentProxy),
                        0
                    );
                }
            }
        }
    }

    function getTournamentDetails(uint256 index)
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
        return
            Tournament(address(tournamentsArray[index])).getTournamentDetails();
    }

    function getTournamentDetailsByAddress(address _tournament)
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
        require(
            tournamentsMapping[_tournament],
            "This contract does not exists"
        );
        return Tournament(_tournament).getTournamentDetails();
    }

    function getImplementation() external view returns (address) {
        return tournamentBeacon.blueprint();
    }

    function getCount() public view returns (uint256 count) {
        return tournamentsArray.length;
    }
}
