// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library VerifySignature {
    using ECDSA for bytes32;

    function verifyMessage(string memory message, bytes memory signature)
        internal
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
            //msg.sender didnt sign address(this) message.
            return false;
        }
    }
}
