// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {ERC721TicketAuction} from "src/ERC721TicketAuction.sol";

contract DeployERC721TicketAuction is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        new ERC721TicketAuction(address(nftAddress));

        vm.stopBroadcast();
    }
}
