// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";

// Merkle tree input file generator script
contract GenerateInput is Script {
    struct Data {
        uint256 amount;
        address claimer;
    }

    struct DataJson {
        Data[] data;
    }

    string private constant _INPUT_PATH = "/script/target/input.json";
    string private constant _INPUT_DATA_PATH = "/script/target/data.json";

    function run() public {
        string memory input = _createJSON();
        // write to the output file the stringified output json tree dumpus
        vm.writeFile(string.concat(vm.projectRoot(), _INPUT_PATH), input);

        console.log("DONE: The output is found at %s", _INPUT_PATH);
    }

    function _readData() private view {
        string memory data = vm.readFile(string.concat(vm.projectRoot(), _INPUT_DATA_PATH));
        bytes memory jsonData = vm.parseJson(data);
        DataJson memory datajson = abi.decode(jsonData, (DataJson));

        for (uint256 i = 0; i < datajson.data.length; ++i) {
            console.log(
                "Address: %s, Amount: %s", datajson.data[i].claimer, datajson.data[i].amount
            );
        }

        console.log("json data len: ", datajson.data.length);
    }

    function _createJSON() private view returns (string memory) {
        string memory data = vm.readFile(string.concat(vm.projectRoot(), _INPUT_DATA_PATH));
        bytes memory jsonData = vm.parseJson(data);
        DataJson memory datajson = abi.decode(jsonData, (DataJson));
        string memory countString = vm.toString(datajson.data.length);

        string memory json =
            string.concat('{ "types": ["address", "uint"], "count":', countString, ',"values": {');
        for (uint256 i = 0; i < datajson.data.length; ++i) {
            if (i == datajson.data.length - 1) {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    vm.toString(datajson.data[i].claimer),
                    '"',
                    ', "1":',
                    '"',
                    vm.toString(datajson.data[i].amount),
                    '"',
                    " }"
                );
            } else {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    vm.toString(datajson.data[i].claimer),
                    '"',
                    ', "1":',
                    '"',
                    vm.toString(datajson.data[i].amount),
                    '"',
                    " },"
                );
            }
        }
        json = string.concat(json, "} }");

        return json;
    }
}
