// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

// Merkle tree input file generator script
contract GenerateInput is Script {
    // uint256 private constant _AMOUNT = 25 * 1e18;
    // string[] private _types = new string[](2);
    // uint256 private _count;
    // string[] private _whitelist = new string[](4);
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
        // _types[0] = "address";
        // _types[1] = "uint";
        // _whitelist[0] = "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D";
        // _whitelist[1] = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
        // _whitelist[2] = "0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd";
        // _whitelist[3] = "0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D";
        // _count = _whitelist.length;
        string memory input = _createJSON();
        // write to the output file the stringified output json tree dumpus
        vm.writeFile(string.concat(vm.projectRoot(), _INPUT_PATH), input);

        console.log("DONE: The output is found at %s", _INPUT_PATH);

        // _readData();
    }

    function _readData() private view {
        string memory data = vm.readFile(
            string.concat(vm.projectRoot(), _INPUT_DATA_PATH)
        );
        bytes memory jsonData = vm.parseJson(data);
        DataJson memory datajson = abi.decode(jsonData, (DataJson));

        for (uint256 i = 0; i < datajson.data.length; ++i) {
            console.log(
                "Address: %s, Amount: %s",
                datajson.data[i].claimer,
                datajson.data[i].amount
            );
        }

        console.log("json data len: ", datajson.data.length);
    }

    function _createJSON() private view returns (string memory) {
        // string memory countString = vm.toString(_count); // convert count to string
        // string memory amountString = vm.toString(_AMOUNT); // convert amount to string

        string memory data = vm.readFile(
            string.concat(vm.projectRoot(), _INPUT_DATA_PATH)
        );
        bytes memory jsonData = vm.parseJson(data);
        DataJson memory datajson = abi.decode(jsonData, (DataJson));
        string memory countString = vm.toString(datajson.data.length);

        string memory json = string.concat(
            '{ "types": ["address", "uint"], "count":',
            countString,
            ',"values": {'
        );
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
