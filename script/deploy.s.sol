// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "src/JoeDexLens.sol";

contract Deploy is Script {
    using stdJson for string;

    struct Deployment{
        address joeFactory;
        address lbFactory;
        address lbLegacyFactory;
        address native_usd_aggregator;
        address w_native;
    }

    string[] chains = ["avalanche"];

    JoeDexLens[] listJoeDexLens = new JoeDexLens[](chains.length);
    ProxyAdmin[] listProxyAdmin = new ProxyAdmin[](chains.length);
    TransparentUpgradeableProxy[] listTransparentUpgradeableProxy = new TransparentUpgradeableProxy[](chains.length);
    
    function run() public returns (JoeDexLens[] memory, ProxyAdmin[] memory , TransparentUpgradeableProxy[] memory) {
        
        string memory json = vm.readFile("script/config/deployments.json");
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        for (uint256 i = 0; i < chains.length; i++) {
            bytes memory rawDeploymentData = json.parseRaw(string(abi.encodePacked(".", chains[i])));
            Deployment memory deployment = abi.decode(rawDeploymentData, (Deployment));

            console.log("\nDeploying Dex Lens on %s", chains[i]);

            vm.createSelectFork(StdChains.getChain(chains[i]).rpcUrl);

            /**
            * Start broadcasting the transaction to the network.
            */
            vm.startBroadcast(deployerPrivateKey);

            ProxyAdmin proxyAdmin = new ProxyAdmin();
            JoeDexLens implementation = new JoeDexLens(
                ILBFactory(deployment.lbFactory),
                ILBLegacyFactory(deployment.lbLegacyFactory),
                IJoeFactory(deployment.joeFactory),
                deployment.w_native
            );

            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(implementation),
                address(proxyAdmin),
                abi.encodeWithSelector(JoeDexLens.initialize.selector, deployment.native_usd_aggregator)
            );

            listJoeDexLens[i] = implementation;
            listProxyAdmin[i] = proxyAdmin;
            listTransparentUpgradeableProxy[i] = proxy;

            vm.stopBroadcast();
            /**
            * Stop broadcasting the transaction to the network.
            */
            }
        return (listJoeDexLens, listProxyAdmin, listTransparentUpgradeableProxy);
    }
}
