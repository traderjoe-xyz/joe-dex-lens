# JoeDexLens

This repository contains JoeDexLens contract, which purpose is to provide token pricing based on arbitrarily chosen markets. 

This contract is not supposed to provide price oracle for any financial operations - should be seen only as helper contract for statistical/analytical purposes.

This contract provides 2 functions for reading token price:
- `getTokenPriceUSD` 
- `getTokenPriceAVAX`

To add markets, functions:
- `addUSDMarkets`
- `addAVAXMarkets`

should be used.

Weighted price based on reserves will be calculated. 

If no markets for a given token was added, AVAX-token and USDC-token from Joe V1 will be used to return the token's price. 



## Install foundry

Foundry documentation can be found [here](https://book.getfoundry.sh/forge/index.html).

### On Linux and macOS

Open your terminal and type in the following command:

```
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. Then install Foundry by running:

```
foundryup
```

To update foundry after installation, simply run `foundryup` again, and it will update to the latest Foundry release.
You can also revert to a specific version of Foundry with `foundryup -v $VERSION`.

### On Windows

If you use Windows, you need to build from source to get Foundry.

Download and run `rustup-init` from [rustup.rs](https://rustup.rs/). It will start the installation in a console.

After this, run the following to build Foundry from source:

```
cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil --bins --locked
```

To update from source, run the same command again.

## Install dependencies

To install dependencies, run the following to install dependencies:

```
forge install
```

___

## Tests

To run tests, run the following command:

```
forge test
```