// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ScriptHelper } from "murky/script/common/ScriptHelper.sol";

// Merkle proof generator script
// To use:
// 1. Run `forge script script/GenerateInput.s.sol` to generate the input file
// 2. Run `forge script script/Merkle.s.sol`
// 3. The output file will be generated in /script/target/output.json

/**
 * @title MakeMerkle
 * @author Ciara Nightingale
 * @author Cyfrin
 *
 * Original Work by:
 * @author kootsZhin
 * @notice https://github.com/dmfxyz/murky
 */
contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; // enables us to use the json cheatcodes for strings

    Merkle private _MERKLE = new Merkle(); // instance of the merkle contract from Murky to do shit

    string private constant _INPUT_PATH = "/script/target/input.json";
    string private constant _OUTPUT_PATH = "/script/target/output.json";

    string private _elements = vm.readFile(string.concat(vm.projectRoot(), _INPUT_PATH)); // get the absolute path
    string[] private _types = _elements.readStringArray(".types"); // gets the merkle tree leaf types from json using forge standard lib cheatcode
    uint256 private _count = _elements.readUint(".count"); // get the number of leaf nodes

    // make three arrays the same size as the number of leaf nodes
    bytes32[] private _leafs = new bytes32[](_count);

    string[] private _inputs = new string[](_count);
    string[] private _outputs = new string[](_count);

    string private _output;

    /// @dev Read the input file and generate the Merkle proof, then write the output file
    function run() public {
        console.log("Generating Merkle Proof for %s", _INPUT_PATH);

        for (uint256 i = 0; i < _count; ++i) {
            string[] memory input = new string[](_types.length); // stringified data (address and string both as strings)
            bytes32[] memory data = new bytes32[](_types.length); // actual data as a bytes32

            for (uint256 j = 0; j < _types.length; ++j) {
                if (compareStrings(_types[j], "address")) {
                    address value = _elements.readAddress(_getValuesByIndex(i, j));
                    // you can't immediately cast straight to 32 bytes as an address is 20 bytes so first cast to uint160 (20 bytes) cast up to uint256 which is 32 bytes and finally to bytes32
                    data[j] = bytes32(uint256(uint160(value)));
                    input[j] = vm.toString(value);
                } else if (compareStrings(_types[j], "uint")) {
                    uint256 value = vm.parseUint(_elements.readString(_getValuesByIndex(i, j)));
                    data[j] = bytes32(value);
                    input[j] = vm.toString(value);
                }
            }
            // Create the hash for the merkle tree leaf node
            // abi encode the data array (each element is a bytes32 representation for the address and the amount)
            // Helper from Murky (ltrim64) Returns the bytes with the first 64 bytes removed
            // ltrim64 removes the offset and length from the encoded bytes. There is an offset because the array
            // is declared in memory
            // hash the encoded address and amount
            // bytes.concat turns from bytes32 to bytes
            // hash again because preimage attack
            _leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(data)))));
            // Converts a string array into a JSON array string.
            // store the corresponding values/inputs for each leaf node
            _inputs[i] = stringArrayToString(input);
        }

        for (uint256 i = 0; i < _count; ++i) {
            // get proof gets the nodes needed for the proof & strigify (from helper lib)
            string memory proof = bytes32ArrayToString(_MERKLE.getProof(_leafs, i));
            // get the root hash and stringify
            string memory root = vm.toString(_MERKLE.getRoot(_leafs));
            // get the specific leaf working on
            string memory leaf = vm.toString(_leafs[i]);
            // get the singified input (address, amount)
            string memory input = _inputs[i];

            // generate the Json output file (tree dump)
            _outputs[i] = _generateJsonEntries(input, proof, root, leaf);
        }

        // stringify the array of strings to a single string
        _output = stringArrayToArrayString(_outputs);
        // write to the output file the stringified output json tree dumpus
        vm.writeFile(string.concat(vm.projectRoot(), _OUTPUT_PATH), _output);

        console.log("DONE: The output is found at %s", _OUTPUT_PATH);
    }

    /// @dev Returns the JSON path of the input file
    // output file output ".values.some-address.some-amount"
    function _getValuesByIndex(uint256 i, uint256 j) private pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }

    /// @dev Generate the JSON entries for the output file
    function _generateJsonEntries(
        string memory inputs,
        string memory proof,
        string memory root,
        string memory leaf
    ) private pure returns (string memory) {
        string memory result = string.concat(
            "{",
            '"inputs":',
            inputs,
            ",",
            '"proof":',
            proof,
            ",",
            '"root":"',
            root,
            '",',
            '"leaf":"',
            leaf,
            '"',
            "}"
        );

        return result;
    }
}
