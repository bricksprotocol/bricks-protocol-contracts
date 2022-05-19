// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tournament.sol";
import "./interfaces/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TournamentBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

//import "@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol";

//import "./WETHGateway.sol";

contract CreateTournamentFactory is OwnableUpgradeable {
    BeaconProxy[] public tournamentsArray;
    mapping(address => bool) tournamentsMapping;
    event tournamentCreated(address tournamentAddress);
    IERC20 ierc20;
    // IWETH iweth;

    address lendingPoolAddressProvider;
    address public lendingPoolAddress;
    address dataProvider;
    //address linkTokenAddress;
    // uint256 linkFundValue;
    uint256 public protocolFees; // 10% - 1000 (support upto 2 decimal places)
    address private verifySignatureAddress;
    address private implementationContract;
    TournamentBeacon public tournamentBeacon;

    // address private oracle;
    // bytes32 private jobId;
    // uint256 private fee;

    function initialize(address impl) public initializer {
        tournamentBeacon = new TournamentBeacon(impl);
        implementationContract = impl;
        //_transferOwnership(tx.origin);
        __Ownable_init();
    }

    // constructor(address impl) {
    //     tournamentBeacon = new TournamentBeacon(impl);
    //     //beacon = new UpgradeableBeacon(impl);
    //     implementationContract = impl;
    // }

    function setProtocolFees(uint256 _protocolFees) public onlyOwner {
        protocolFees = _protocolFees;
    }

    function setLendingPoolAddressProvider(address _lendingPoolAddressProvider)
        public
        onlyOwner
    {
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        lendingPoolAddress = IPoolAddressesProvider(_lendingPoolAddressProvider)
            .getPool();
        dataProvider = IPoolAddressesProvider(_lendingPoolAddressProvider)
            .getPoolDataProvider();
    }

    function getLendingPoolAddressProvider()
        public
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
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _asset,
        uint256 _initial_invested_amount,
        address _aAssetAddress,
        bool _isNativeAsset
    ) public payable {
        BeaconProxy tournamentProxy = new BeaconProxy(
            address(tournamentBeacon),
            abi.encodeWithSelector(Tournament(address(0)).initialize.selector)
        );
        tournamentsArray.push(tournamentProxy);
        tournamentsMapping[address(tournamentProxy)] = true;
        Tournament(address(tournamentProxy)).createPool({
            _tournamentURI: _tournamentURI,
            _tournamentStart: _tournamentStart,
            _tournamentEnd: _tournamentEnd,
            _tournamentEntryFees: _tournamentEntryFees,
            _lending_pool_address: lendingPoolAddress,
            _dataProvider: dataProvider,
            _asset: _asset,
            _initial_invested_amount: _initial_invested_amount,
            _protocolFees: protocolFees,
            _sender: msg.sender,
            _aAssetAddress: _aAssetAddress,
            _isNativeAsset: _isNativeAsset
        });
        if (_initial_invested_amount != 0) {
            if (_isNativeAsset) {
                WETHGateway gateway = new WETHGateway(_asset, address(this));
                gateway.authorizePool(lendingPoolAddress);
                gateway.depositETH{value: msg.value}(
                    lendingPoolAddress,
                    address(tournamentProxy),
                    0
                );
            } else {
                ierc20 = IERC20(_asset);
                require(
                    ierc20.transferFrom(
                        msg.sender,
                        address(this),
                        _initial_invested_amount
                    ),
                    "Transfer failed!"
                );
                ierc20.approve(lendingPoolAddress, _initial_invested_amount);
                IPool(lendingPoolAddress).supply(
                    _asset,
                    _initial_invested_amount,
                    address(tournamentProxy),
                    0
                );
            }
        }
        emit tournamentCreated(address(tournamentProxy));
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
            address,
            address payable[] memory
        )
    {
        return
            Tournament(address(tournamentsArray[_index]))
                .getTournamentDetails();
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

    function getImplementation() public view returns (address) {
        return tournamentBeacon.blueprint();
    }
}
