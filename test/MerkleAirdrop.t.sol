// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { MockToken } from "../src/contracts/MockToken.sol";
import { MerkleAirdrop } from "../src/contracts/MerkleAirdrop.sol";
import { GenerateInput } from "../script/GenerateInput.s.sol";
import { MakeMerkle } from "../script/GenerateMerkle.s.sol";
import {
    MerkleAirdrop__AlreadyClaimed, MerkleAirdrop__InvalidProof
} from "../src/contracts/Errors.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdropTest is Test {
    using stdJson for string;

    struct Data {
        uint256 amount;
        address claimer;
    }

    struct DataJson {
        Data[] data;
    }

    Data[] private _dataArray;

    mapping(address claimer => bytes32[] proof) private _claimerToProof;

    MockToken private _mockToken;
    MerkleAirdrop private _merkleAirdrop;
    GenerateInput private _generateInput;
    MakeMerkle private _makeMerkle;

    string private constant _INPUT_DATA_PATH = "/script/target/data.json";
    string private constant _MERKLE_PATH = "/script/target/output.json";

    address private _deployer = vm.addr(0x1);
    address private _owner = vm.addr(0x2);

    bytes32 private _root;
    uint256 private _totalAmountToBeClaimed;

    function setUp() external {
        string memory eip712name = "EIP_712_Test";
        string memory eip712version = "1";

        vm.startPrank(_deployer);

        _generateInput = new GenerateInput();
        _generateInput.run();

        _makeMerkle = new MakeMerkle();
        _makeMerkle.run();

        _deployHelper();

        _mockToken = new MockToken();
        _merkleAirdrop = new MerkleAirdrop(eip712name, eip712version, _root, address(_mockToken));

        _mockToken.transferOwnership(_owner);

        vm.stopPrank();

        vm.startPrank(_owner);

        _mockToken.mint(_owner, _totalAmountToBeClaimed);
        _mockToken.transfer(address(_merkleAirdrop), _totalAmountToBeClaimed);

        vm.stopPrank();
    }

    function testClaim() external {
        for (uint256 i = 0; i < _dataArray.length; ++i) {
            address claimer = _dataArray[i].claimer;
            uint256 amountToClaim = _dataArray[i].amount;
            _testClaimHelper(claimer, amountToClaim, "", "");
            assertEq(_mockToken.balanceOf(claimer), amountToClaim);
            assertEq(_merkleAirdrop.isAirdropClaimed(claimer), true);
        }
    }

    function testClaimShouldFail() external {
        address claimer = _dataArray[1].claimer;
        uint256 amountToClaim = _dataArray[0].amount;
        address unauthorizedClaimer = _dataArray[1].claimer;

        bytes32[] memory merkleProof = _claimerToProof[unauthorizedClaimer];

        vm.prank(unauthorizedClaimer);
        vm.expectRevert(MerkleAirdrop__InvalidProof.selector);

        _merkleAirdrop.claim(unauthorizedClaimer, amountToClaim, merkleProof, "", "");

        assertEq(_merkleAirdrop.isAirdropClaimed(unauthorizedClaimer), false);
        assertEq(_merkleAirdrop.isAirdropClaimed(claimer), false);
    }

    function testClaimTwiceShouldFail() external {
        address claimer = _dataArray[2].claimer;
        uint256 amountToClaim = _dataArray[2].amount;

        bytes32[] memory merkleProof = _claimerToProof[claimer];

        assertEq(_mockToken.balanceOf(claimer), 0);

        vm.prank(claimer);
        _merkleAirdrop.claim(claimer, amountToClaim, merkleProof, "", "");

        assertEq(_merkleAirdrop.isAirdropClaimed(claimer), true);

        vm.expectRevert(MerkleAirdrop__AlreadyClaimed.selector);
        _merkleAirdrop.claim(claimer, amountToClaim, merkleProof, "", "");

        assertEq(_mockToken.balanceOf(claimer), amountToClaim);
    }

    function testDeploy() external view {
        assertEq(_merkleAirdrop.getMerkleRoot(), _root);
        assertEq(_merkleAirdrop.getAirdropToken(), address(_mockToken));
    }

    function testSignatureVerification() external {
        (address claimer, uint256 pvKey) = makeAddrAndKey("claimer");
        address _gasPayer = vm.addr(0x3);

        string memory message = "I approve the gas payer to claim on my behalf";
        bytes32 digest = _merkleAirdrop.getMessageHash(message, claimer, _gasPayer);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool verified = _merkleAirdrop.verifySignature(claimer, _gasPayer, message, signature);
        assertTrue(verified);
    }

    function _testClaimHelper(
        address claimer,
        uint256 amountToClaim,
        string memory message,
        bytes memory signature
    ) private {
        bytes32[] memory merkleProof = _claimerToProof[claimer];

        vm.prank(claimer);
        _merkleAirdrop.claim(claimer, amountToClaim, merkleProof, message, signature);
    }

    function _deployHelper() private {
        string memory merkleDataJson = vm.readFile(string.concat(vm.projectRoot(), _MERKLE_PATH));
        bytes memory jsonMerkleRoot = merkleDataJson.parseRaw("[0].root");

        _root = abi.decode(jsonMerkleRoot, (bytes32));

        string memory data = vm.readFile(string.concat(vm.projectRoot(), _INPUT_DATA_PATH));

        bytes memory jsonData = vm.parseJson(data);
        DataJson memory dataJson = abi.decode(jsonData, (DataJson));

        uint256 dataLen = dataJson.data.length;

        for (uint256 i = 0; i < dataLen; ++i) {
            _dataArray.push(dataJson.data[i]);
            _totalAmountToBeClaimed += dataJson.data[i].amount;

            bytes memory jsonProof =
                merkleDataJson.parseRaw(string.concat("[", vm.toString(i), "].proof"));
            bytes32[] memory proof = abi.decode(jsonProof, (bytes32[]));

            _claimerToProof[dataJson.data[i].claimer] = proof;
        }

        assertGt(_dataArray.length, 1);
        assertGt(_totalAmountToBeClaimed, 0);
    }
}
