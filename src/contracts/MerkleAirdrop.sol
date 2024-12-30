// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { MerkleAirdrop__AlreadyClaimed, MerkleAirdrop__InvalidProof } from "./Errors.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    struct AirdropClaim {
        string message;
        address claimer;
        address gasPayer;
    }

    mapping(address claimer => bool claimed) private _airdropClaimed;
    IERC20 private _airdropToken;

    bytes32 private constant _AIRDROP_CLAIM_TYPE_HASH =
        keccak256("AirdropClaim(string message,address claimer,address gasPayer)");

    bytes32 private _merkleRoot;

    event AirdropClaimed(address claimer, uint256 amount);

    constructor(string memory name, string memory version, bytes32 merkleRoot, address token)
        EIP712(name, version)
    {
        _merkleRoot = merkleRoot;
        _airdropToken = IERC20(token);
    }

    function claim(
        address claimer,
        uint256 amount,
        bytes32[] calldata merkleProof,
        string calldata message,
        bytes memory signature
    ) external {
        if (_airdropClaimed[claimer] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if ((bytes(message).length != 0) && (signature.length != 0)) {
            verifySignature(claimer, msg.sender, message, signature);
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));

        if (!MerkleProof.verify(merkleProof, _merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        _airdropClaimed[claimer] = true;
        _airdropToken.safeTransfer(claimer, amount);

        emit AirdropClaimed(claimer, amount);
    }

    function isAirdropClaimed(address claimer) external view returns (bool) {
        return _airdropClaimed[claimer];
    }

    function getAirdropToken() external view returns (address) {
        return address(_airdropToken);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function verifySignature(
        address claimer,
        address gasPayer,
        string calldata message,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 digest = getMessageHash(message, claimer, gasPayer);
        (address recovered,,) = ECDSA.tryRecover(digest, signature);

        return claimer == recovered;
    }

    function getMessageHash(string calldata message, address claimer, address gasPayer)
        public
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _AIRDROP_CLAIM_TYPE_HASH,
                    AirdropClaim({ message: message, claimer: claimer, gasPayer: gasPayer })
                )
            )
        );
    }
}
