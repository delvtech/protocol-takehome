// // SPDX-License-Identifier: Apache-2.0
// pragma solidity 0.8.22;

// import {Test} from "forge-std/Test.sol";
// import {IHyperdrive} from "hyperdrive/src/interfaces/IHyperdrive.sol";
// import {LPAndChill} from "../contracts/LPAndChill.sol";

// contract LPAndChillTest is Test {
//     /// @dev The mainnet RPC URL environment variable.
//     string internal MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

//     /// @dev The block to fork from.
//     uint256 internal constant FORK_BLOCK = 20843705;

//     /// @dev The stUSD Hyperdrive instance. This uses Angle's stUSD as a yield
//     ///      source and has USDA as a base token (hint: you can call
//     ///      `HYPERDRIVE.baseToken()` to get the base token).
//     IHyperdrive internal constant HYPERDRIVE =
//         IHyperdrive(0xA4090183878d5B7b6Ad104863743dd7E58985321);

//     /// @dev The LPAndChill vault.
//     LPAndChill internal chill;

//     /// @notice Sets up the test suite.
//     function setUp() public {
//         // Set up a mainnet fork.
//         uint256 mainnetForkId = vm.createFork(MAINNET_RPC_URL);
//         vm.selectFork(mainnetForkId);
//         vm.rollFork(FORK_BLOCK);

//         // Deploy a LPAndChill vault that connects to the stUSD Hyperdrive pool.
//         chill = new LPAndChill(
//             "stUSD and chill",
//             "STUSD-AND-CHILL",
//             HYPERDRIVE,
//             true
//         );
//     }

//     // ╭─────────────────────────────────────────────────────────╮
//     // │ Tests                                                   │
//     // ╰─────────────────────────────────────────────────────────╯

//     // FIXME: Add your tests here.
// }
