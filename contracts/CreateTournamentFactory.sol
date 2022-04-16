// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Tournament.sol";
//import "./interfaces/IERC20.sol";
//import "./interfaces/IPool.sol";
//import "./interfaces/IPoolAddressesProvider.sol";
import "./interfaces/IWeth.sol";
import "./aave/v2/ILendingPool.sol";
import "./aave/v2/ILendingPoolAddressesProvider.sol";

contract CreateTournamentFactory is Ownable {
    Tournament[] public tournamentsArray;
    mapping(address => bool) tournamentsMapping;
    event tournamentCreated(address tournamentAddress);
    ERC20 ierc20;
    IWeth iweth;

    address lendingPoolAddressProvider;
    address lendingPoolAddress;
    address dataProvider;
    address linkTokenAddress;
    uint256 linkFundValue;
    uint256 public protocolFees; // 10% - 1000 (support upto 2 decimal places)

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    function setMinimumLinkfunder(uint256 _value) public onlyOwner {
        linkFundValue = _value;
    }

    function setProtocolFees(uint256 _protocolFees) public onlyOwner {
        protocolFees = _protocolFees;
    }

    function setLendingPoolAddressProvider(address _lendingPoolAddressProvider)
        public
        onlyOwner
    {
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        lendingPoolAddress = ILendingPoolAddressesProvider(
            _lendingPoolAddressProvider
        ).getLendingPool();
        dataProvider = ILendingPoolAddressesProvider(
            _lendingPoolAddressProvider
        ).getAddress(
                0x0100000000000000000000000000000000000000000000000000000000000000
            );
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

    function setOracleData(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) public onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function getOracleData()
        public
        view
        returns (
            address,
            bytes32,
            uint256
        )
    {
        return (oracle, jobId, fee);
    }

    function setLinkTokenAddress(address _link) public onlyOwner {
        linkTokenAddress = _link;
    }

    function getLinkTokenAddress() public view returns (address) {
        return linkTokenAddress;
    }

    function createTournamentPool(
        string memory _tournamentURI,
        uint256 _tournamentStart,
        uint256 _tournamentEnd,
        uint256 _tournamentEntryFees,
        address _asset,
        uint256 _initial_invested_amount
    ) public {
        ierc20 = ERC20(_asset);
        //iweth = IWeth(_asset);
        Tournament tournament = new Tournament();
        tournamentsArray.push(tournament);
        tournamentsMapping[address(tournament)] = true;
        tournament.createPool({
            _tournamentURI: _tournamentURI,
            _tournamentStart: _tournamentStart,
            _tournamentEnd: _tournamentEnd,
            _tournamentEntryFees: _tournamentEntryFees,
            _lending_pool_address: lendingPoolAddress,
            _dataProvider: dataProvider,
            _asset: _asset,
            _initial_invested_amount: _initial_invested_amount,
            _protocolFees: protocolFees,
            _sender: msg.sender
        });
        if (_initial_invested_amount != 0) {
            // require(
            //     ierc20.transferFrom(
            //         msg.sender,
            //         address(this),
            //         _initial_invested_amount
            //     )
            // );
            // ierc20.approve(address(tournament), 10**6);

            require(
                ierc20.transferFrom(
                    msg.sender,
                    address(this),
                    _initial_invested_amount
                ),
                "USDC Transfer failed!"
            );
            // ierc20.approve(
            //     lendingPoolAddressProvider,
            //     _initial_invested_amount
            // );
            ierc20.approve(lendingPoolAddress, _initial_invested_amount);

            // IPool(IPoolAddressesProvider(lendingPoolAddressProvider).getPool())
            //     .supply(
            //         0xe22da380ee6B445bb8273C81944ADEB6E8450422,
            //         500 * 10**6,
            //         msg.sender,
            //         0
            //     );

            ILendingPool(lendingPoolAddress).deposit(
                _asset,
                _initial_invested_amount,
                address(tournament),
                0
            );

            // IWethGateway(0x509B2506FbA1BD41765F6A82C7B0Dd4229191768).depositETH(
            //         IPoolAddressesProvider(lendingPoolAddressProvider)
            //             .getPool(),
            //         address(tournament),
            //         0
            //     );
        }

        // IERC20 linkTokenContract = IERC20(linkTokenAddress);
        // linkTokenContract.approve(address(this), linkFundValue);
        // linkTokenContract.transferFrom(
        //     address(this),
        //     address(createTournament),
        //     linkFundValue
        // );
        emit tournamentCreated(address(tournament));
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
        return tournamentsArray[_index].getTournamentDetails();
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
            "This tournament contract does not exists"
        );
        return Tournament(_tournament).getTournamentDetails();
    }
}
