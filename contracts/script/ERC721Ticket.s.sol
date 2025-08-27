// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {ERC721Ticket} from "src/ERC721Ticket.sol";

contract DeployERC721Ticket is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new ERC721Ticket();

        vm.stopBroadcast();
    }
}
