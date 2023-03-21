// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "../../src/JoeDexLens.sol";

contract Deploy is Script {
    address constant wnative = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant native_usd_aggregator = 0x0A77230d17318075983913bC2145DB16C7366156;

    ILBFactory constant lbFactory = ILBFactory(address(0)); // Not deployed yet
    ILBLegacyFactory constant lbLegacyFactory = ILBLegacyFactory(0x2950b9bd19152C91d69227364747b3e6EFC8Ab7F);
    IJoeFactory constant joeFactory = IJoeFactory(0xF5c7d9733e5f53abCC1695820c4818C59B457C2C);

    function run() public returns (JoeDexLens, ProxyAdmin, TransparentUpgradeableProxy) {
        vm.createSelectFork(vm.rpcUrl("avalanche"));

        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        /**
         * Start broadcasting the transaction to the network.
         */
        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin proxyAdmin = new ProxyAdmin();
        JoeDexLens implementation = new JoeDexLens(
            lbFactory,
            lbLegacyFactory,
            joeFactory,
            wnative
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(address)", native_usd_aggregator)
            
        );

        vm.stopBroadcast();
        /**
         * Stop broadcasting the transaction to the network.
         */

        return (implementation, proxyAdmin, proxy);
    }
}
