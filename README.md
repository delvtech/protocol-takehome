# Take-Home Summary -- Sean

## Completed Items

### Required -- all done
    - [x] Implement the core ERC4626 functions like `deposit`, `mint`, `withdraw`, `redeem`, `totalAssets` ---  COMPLETED
    - [x] Implement proper error handling and input validation ---  COMPLETED
    - [x] Include events for important actions --- COMPLETED
    - [x] Implement some tests for the code that you wrote --- COMPLETED
### Optional
    - [x] Implement a fee mechanism for the vault, charging a small percentage of yields --- COMPLETED
### Bonus
    - [x] LPAndChill vault will be created by a factory contract, because I see there are quite a number of underlying assets supported by Hyperdrive and there may be more in the future. So scalability is needed. --- COMPLETED
    - [x] Applied the Beacon Proxy Pattern to keep the upgradability, as opposed to the Miminal Proxy pattern. --- COMPLETED
    - [x] Deployed a ServiceConfiguration contract to hold access control for priviledged functions. Beside the DEFAULT ADMIN which is the deployer of the ServiceConfig, additional 2 roles are set up:
        * Deployer: can upgrade the implementation contract for the vault --- COMPLETED
        * Operator: can perform housekeeping operations like withdrawing the fee, set the fee BPS...etc. --- COMPLETED
    - [x] Add a pausible mechanism for better operational control of the protocol --- COMPLETED
    
## Future Improvement Items
    - [ ] The current testing only covers all the typical functionalities, but does not have 100% line coverage. Need to add more testing when I get more time --- TODO
    - [ ] Some repeated logic code should be abstracted out into a library contract --- TODO
    - [ ] Add a life cycle enum (initialized, active, closed) for the vault status to obtain the authority to fully retire it --- TODO
    - [ ] When the underlying base asset is WETH, the contract does not take native ETH withdraw, not a big deal but still is some kind of glitch --- TO FIX
    - [ ] Replace all the customized error messages to customized error codes --- TODO
    - [ ] Need to come up with more comprehensive logic regarding the APR range guard and price slippage guard to better integrate with the dependency contract of Hyperdrive; at the moment I'm using simple rule based guards. --- TODO

## HOW TO USE IT
#### 
First, please refer to [this UML diagram](architecture.png) to see the design of the project. 

The project is built with Foundry, so just run Foundry commands on it. For example, to run the test suite, use `forge test`, then you should be seeing something like this:
```
xuxiangy@147ddaa435c7 protocol-takehome % forge test
[⠒] Compiling...
No files changed, compilation skipped

Ran 8 tests for test/LPAndChill.t.sol:LPAndChillTest
[PASS] testDeposit() (gas: 647171)
[PASS] testMint() (gas: 760220)
[PASS] testRedeem() (gas: 1142823)
[PASS] testSetServiceFeeBpsAsNonOperator() (gas: 29706)
[PASS] testSetServiceFeeBpsAsOperator() (gas: 38223)
[PASS] testWithdraw() (gas: 1032490)
[PASS] testWithdrawFeeAsNonOperator() (gas: 1072581)
[PASS] testWithdrawFeeAsOperator() (gas: 1089067)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 1.46s (50.03ms CPU time)

Ran 1 test suite in 1.47s (1.46s CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)
```

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

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

This project is a significant undertaking, and we don't expect you to complete it. Do what you can in the provided 10 hours and think about things like what you still need to do, what you would change, etc. We're more interested in seeing how you tackle a challenging problem than in a perfect finished product.

Good luck! We look forward to seeing your implementation of the "LP and Chill" vault.
