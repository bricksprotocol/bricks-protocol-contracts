// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IWETHGateway} from "./interfaces/IWethGateway.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/core-v3/contracts/interfaces/IAToken.sol";
import {ReserveConfiguration} from "@aave/core-v3/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "@aave/core-v3/contracts/protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";

contract WETHGateway is IWETHGateway, Ownable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IWeth internal immutable weth;

    /**
     * @dev Sets the weth address and the PoolAddressesProvider address. Infinite approves pool.
     * @param wethAddress Address of the Wrapped Ether contract
     * @param owner Address of the owner of address(this) contract
     **/
    constructor(address wethAddress, address owner) {
        weth = IWeth(wethAddress);
        transferOwnership(owner);
    }

    modifier validAddress(address impl) {
        require(impl != address(0), "Address is 0");
        _;
    }

    function authorizePool(address pool) external onlyOwner returns (bool) {
        bool approved = weth.approve(pool, type(uint256).max);
        return approved;
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param pool address of the targeted underlying pool
     * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override onlyOwner {
        weth.deposit{value: msg.value}();
        IPool(pool).deposit(address(weth), msg.value, onBehalfOf, referralCode);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param pool address of the targeted underlying pool
     * @param amount amount of aWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     */
    function withdrawETH(
        address pool,
        uint256 amount,
        address to
    ) external override onlyOwner validAddress(to) {
        IAToken aWETH = IAToken(
            IPool(pool).getReserveData(address(weth)).aTokenAddress
        );
        uint256 ownerBalance = aWETH.balanceOf(owner());
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = ownerBalance;
        }
        bool transferStatus = aWETH.transferFrom(
            owner(),
            address(this),
            amountToWithdraw
        );

        if (transferStatus) {
            uint256 amountWithdrawn = IPool(pool).withdraw(
                address(weth),
                amountToWithdraw,
                address(this)
            );
            bool approved = weth.approve(address(this), amountToWithdraw);
            if (approved && amountWithdrawn > 0) {
                weth.withdraw(amountToWithdraw);
                (bool success, ) = to.call{value: amountToWithdraw}(
                    new bytes(0)
                );
                require(success, "ETH_TRANSFER_FAILED");
            }
        }
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    // function _safeTransferETH(address to, uint256 value) internal {
    //     require(participantsRegistered[to], "Particpant isn't registered");
    //     if (participantsRegistered[to]) {
    //         (bool success, ) = to.call{value: value}(new bytes(0));
    //         require(success, "ETH_TRANSFER_FAILED");
    //     }
    // }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to address(this) contract.
     */
    receive() external payable {
        require(msg.sender == address(weth), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}
