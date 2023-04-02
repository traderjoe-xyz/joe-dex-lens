// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "src/JoeDexLens.sol";
import "script/deploy.s.sol";

contract TransferOwnership is Script {
    using stdJson for string;

    string[] chains = ["avalanche"];

    JoeDexLens[] listJoeDexLens = new JoeDexLens[](chains.length);
    ProxyAdmin[] listProxyAdmin = new ProxyAdmin[](chains.length);
    TransparentUpgradeableProxy[] listTransparentUpgradeableProxy = new TransparentUpgradeableProxy[](chains.length);

    function run() public {
        
        string memory json = vm.readFile("script/config/deployments.json");
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        Deploy deploy = new Deploy();
        (listJoeDexLens, listProxyAdmin, listTransparentUpgradeableProxy) = deploy.run();

        for (uint256 i = 0; i < chains.length; i++) {
            bytes memory rawDeploymentData = json.parseRaw(string(abi.encodePacked(".", chains[i])));
            Deploy.Deployment memory deployment = abi.decode(rawDeploymentData, (Deploy.Deployment));

            /**
            * Start broadcasting the transaction to the network.
            */
            vm.createSelectFork(StdChains.getChain(chains[i]).rpcUrl);     

            vm.startBroadcast(deployerPrivateKey);

            listProxyAdmin[i].changeProxyAdmin(listTransparentUpgradeableProxy[i], deployment.multisig);
            listProxyAdmin[i] = ProxyAdmin(deployment.multisig);
            /**
            * Stop broadcasting the transaction to the network.
            */
        }
    }
}
