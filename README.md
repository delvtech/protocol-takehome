# Take-Home Assignment:

Implement an "LP and Chill" Vault for Hyperdrive Protocol

## Background

Hyperdrive is a fixed-rates protocol that allows traders to long and short bonds with terms on demand. To increase distribution and accessibility for liquidity providers (LPs), we want to implement an ERC4626 vault that wraps the LP position. This vault, which we're calling the "LP and Chill" vault, will allow users to easily deposit into a managed position that LPs into the Hyperdrive protocol.

## Objective

Your task is to implement the "LP and Chill" vault as an ERC4626-compliant contract that interacts with the Hyperdrive protocol. This vault should allow users to deposit base assets, which the vault then uses to provide liquidity to Hyperdrive. The vault should also handle the complexities of managing the LP position, including adding liquidity, removing liquidity, and handling any rewards or fees.

## Requirements

Complete the "LP And Chill" vault that was started in `contracts/LPAndChill.sol`. This vault should invest all of its assets into the Hyperdrive LP position. The vault should accept deposits in the base asset used by Hyperdrive. Implement the core ERC4626 functions, ensuring they interact correctly with Hyperdrive:

- `deposit`
- `mint`
- `withdraw`
- `redeem`
- `totalAssets`

You can implement these functions as standalone functions or using Solady hooks.
You'll need to make sure that any base that is deposited is invested into the LP
position of the corresponding Hyperdrive pool and that any shares that are
withdrawn are taken out of the existing LP position.

When removing liquidity on Hyperdrive, it's possible to receive withdrawal shares.
For the purposes of this takehome, you can just revert with a custom error code
is removing liquidity receives withdrawal shares.

Some additional things that you should think about:

- Implement proper error handling and input validation.
- Include events for important actions (e.g., deposits, withdrawals, liquidity additions/removals).
- (Optional) Implement a fee mechanism for the vault, charging a small percentage of yields.
- Think through any security assumptions that you made or concerns that you have with this implementation. We'll talk about this in the takehome review session.

In addition to this engineering work, you should implement some tests for the code that you wrote.

## Resources

- The [Hyperdrive Docs](https://docs.hyperdrive.box/) will help orient you in how Hyperdrive works and how to make use of it.
- The [`IHyperdrive`](https://github.com/delvtech/hyperdrive/blob/main/contracts/src/interfaces/IHyperdrive.sol) interface contains all of the errors, events, structs, stateful functions, and getter functions on Hyperdrive.
- The [`IHyperdriveCore`](https://github.com/delvtech/hyperdrive/blob/main/contracts/src/interfaces/IHyperdriveCore.sol) interface outlines the main functions of the Hyperdrive protocol. It may be easier to read through this than to read through all of `IHyperdrive`.

If anything is unclear, let us know, and we are happy to clarify.

## Submission Guidelines

Open a PR to the takehome repository with your submission. Write up a PR description with anything you

Submit your code as a Git repository. Include all necessary contracts, tests, and documentation. Provide clear instructions on how to set up and run your project. You have 5 days to complete this assignment from the time you receive it.

While this assignment is designed to be completed in approximately 10-16 hours, please don't feel pressured to spend more than 20 hours on it. We value your time and are more interested in your approach and understanding rather than a perfect implementation.

Good luck! We look forward to seeing your implementation of the "LP and Chill" vault.
