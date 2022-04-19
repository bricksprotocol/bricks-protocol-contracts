// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Verify {
    using ECDSA for bytes32;

    function verifyMessage(uint256 message, bytes memory signature)
        public
        view
        returns (bool)
    {
        //hash the plain text message
        bytes32 messagehash = keccak256(bytes(Strings.toString(message)));

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
