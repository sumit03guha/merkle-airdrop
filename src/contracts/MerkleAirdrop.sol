// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {MerkleAirdrop__AlreadyClaimed, MerkleAirdrop__InvalidProof} from "./Errors.sol";

contract MerkleAirdrop is Ownable {
    using SafeERC20 for IERC20;

    bytes32 private _merkleRoot;
    IERC20 private _airdropToken;

    mapping(address claimer => bool claimed) private _airdropClaimed;

    event AirdropClaimed(address claimer, uint256 amount);

    constructor(bytes32 merkleRoot, address token) Ownable(msg.sender) {
        _merkleRoot = merkleRoot;
        _airdropToken = IERC20(token);
    }

    function claim(
        address claimer,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (_airdropClaimed[claimer] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(claimer, amount)))
        );

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
}
