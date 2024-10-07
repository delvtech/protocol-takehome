// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IHyperdrive} from "hyperdrive/src/interfaces/IHyperdrive.sol";
import {LPAndChill} from "../contracts/LPAndChill.sol";
import {LPAndChillFactory} from "../contracts/factories/LPAndChillFactory.sol";
import {IERC20} from "hyperdrive/src/interfaces/IERC20.sol";
import {IServiceConfiguration} from "../contracts/interfaces/IServiceConfiguration.sol";
import {IVault} from "../contracts/interfaces/IVault.sol";
import {ServiceConfiguration} from "../contracts/ServiceConfiguration.sol";
import {VaultFactory} from "../contracts/factories/VaultFactory.sol";
import {Vault} from "../contracts/Vault.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LPAndChillTest is Test {
    /// @dev The mainnet RPC URL environment variable.
    string internal MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    /// @dev The block to fork from.
    uint256 internal constant FORK_BLOCK = 20843705;

    /// @dev The stUSD Hyperdrive instance. This uses Angle's stUSD as a yield
    ///      source and has USDA as a base token (hint: you can call
    ///      `HYPERDRIVE.baseToken()` to get the base token).
    IHyperdrive internal constant HYPERDRIVE =
        IHyperdrive(0xA4090183878d5B7b6Ad104863743dd7E58985321);

    /// @dev The LPAndChill factory.
    LPAndChillFactory internal factory;

    /// @dev The LPAndChill vault.
    LPAndChill internal chill;

    /// @dev The asset to be used in the tests (e.g., stUSD).
    IERC20 internal asset;

    /// @dev The service configuration contract.
    ServiceConfiguration internal serviceConfiguration;

    ERC1967Proxy public proxy;

    /// @dev The vault factory contract.
    VaultFactory internal vaultFactory;

    /// @dev The operator address for testing.
    address internal operator = makeAddr("OPERATOR");

    /// @notice Sets up the test suite.
    function setUp() public {
        // Set up a mainnet fork.
        uint256 mainnetForkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetForkId);
        vm.rollFork(FORK_BLOCK);

        // Deploy the ServiceConfiguration implementation contract
        ServiceConfiguration implementation = new ServiceConfiguration();

        // Deploy the UUPS proxy for ServiceConfiguration
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(ServiceConfiguration.initialize.selector)
        );

        // Cast the proxy to IServiceConfiguration
        serviceConfiguration = ServiceConfiguration(address(proxy));

        // Grant the operator role to the operator address
        serviceConfiguration.grantRole(serviceConfiguration.OPERATOR_ROLE(), operator);

        // Grant the deployer role to this address
        serviceConfiguration.grantRole(serviceConfiguration.DEPLOYER_ROLE(), address(this));

        // Set the asset to be used in the tests (e.g., stUSD),
        // and, set it as valid liquidity assets in the serviceConfig
        asset = IERC20(HYPERDRIVE.baseToken());
        vm.prank(operator);
        serviceConfiguration.setLiquidityAsset(address(asset), true);

        // Deploy the VaultFactory contract using the ServiceConfiguration address
        vaultFactory = new VaultFactory(address(serviceConfiguration));

        // Deploy the LPAndChill implementation contract and link it to its Beacon
        Vault feeVaultImplementation = new Vault();
        vaultFactory.setImplementation(address(feeVaultImplementation));


        // Deploy the LPAndChillFactory using the VaultFactory address
        factory = new LPAndChillFactory(address(serviceConfiguration), address(vaultFactory));

        // Deploy the LPAndChill implementation contract and link it to its Beacon
        LPAndChill lpAndChillImplementation = new LPAndChill();
        factory.setImplementation(address(lpAndChillImplementation));

        // Deploy a LPAndChill vault that connects to the stUSD Hyperdrive pool.
        vm.prank(operator);
        chill = LPAndChill(factory.createLPAndChill(300, "stUSD and chill", "STUSD-AND-CHILL", address(HYPERDRIVE), true));
    }

    // ╭─────────────────────────────────────────────────────────╮
    // │ Tests                                                   │
    // ╰─────────────────────────────────────────────────────────╯

    function testDeposit() public {
        uint256 depositAmount = 1000 * 10 ** (asset.decimals()); // Adjust based on decimals

        // Transfer some assets to the test contract
        deal(address(asset), address(this), depositAmount);

        uint256 initialBalance = asset.balanceOf(address(this));
        asset.approve(address(chill), depositAmount);

        // Deposit into the LPAndChill contract
        uint256 shares = chill.deposit(depositAmount, address(this));

        // Check that shares were minted
        assert(shares > 0);
        assert(chill.balanceOf(address(this)) == shares);

        // Check that the asset balance has decreased by the deposit amount
        uint256 newBalance = asset.balanceOf(address(this));
        assert(newBalance == initialBalance - depositAmount);
    }

    function testMint() public {

        // Sean: Adjust based on decimals AND THE OFFSET, because the offset may easily
        // reduce the number by too much so it fails Hyperdrive's _minimumTransactionAmount threshold 
        uint256 mintAmount = 1000 * 10 ** (asset.decimals() + 15); 
        
        uint256 requiredAssets = chill.previewMint(mintAmount);
        
        deal(address(asset), address(this), requiredAssets);
        uint256 initialBalance = asset.balanceOf(address(this));
        asset.approve(address(chill), requiredAssets);

        // Mint shares
        uint256 assets = chill.mint(mintAmount, address(this));

        // Check that assets were minted
        assert(assets > 0);
        assert(chill.balanceOf(address(this)) == mintAmount);
        
        // Check that the asset balance has decreased by the required amount
        uint256 newBalance = asset.balanceOf(address(this));
        assert(newBalance == initialBalance - assets);
    }

    function testWithdraw() public {
        uint256 depositAmount = 1000 * 10 ** (asset.decimals()); // Adjust based on decimals

        // Transfer some assets to the test contract
        deal(address(asset), address(this), depositAmount);
        asset.approve(address(chill), depositAmount);

        // Deposit into the LPAndChill contract
        uint256 initialShares = chill.deposit(depositAmount, address(this));

        // Give it some time and let the yield grow
        skip(60*60*24*100);

        // Withdraw just half of the amount, so the fee mechasim won't bother this test
        uint256 withdrawAmount = 500 * 10 ** (asset.decimals()); 

        uint256 balanceBefore = asset.balanceOf(address(this));
        // Withdraw from the LPAndChill contract
        chill.approve(address(chill), type(uint256).max);
        asset.approve(address(chill), type(uint256).max);
        uint256 shares = chill.withdraw(withdrawAmount, address(this), address(this));


        // Check that shares were burned
        assert(shares > 0);
        assert(chill.balanceOf(address(this)) == initialShares - shares);

        // Check that the asset balance has increased
        uint256 balanceAfter = asset.balanceOf(address(this));

        // Sean: Weak check in the assertion without quantifying the delta, because
        //      the amount received may be different than the amount specified to 
        //      withdraw, due to the pricing mechanism of Hyperdrive LP.
        assert(balanceAfter > balanceBefore); 
    }

    function testRedeem() public {
        uint256 initialShares = 1000 * 10 ** (asset.decimals() + 15); // Adjust based on decimals and the offset
        uint256 expectedAssets = chill.previewRedeem(initialShares);

        // Transfer some assets to the test contract
        deal(address(asset), address(this), expectedAssets);
        asset.approve(address(chill), expectedAssets);

        // Deposit into the LPAndChill contract
        chill.deposit(expectedAssets, address(this));

        // Redeem just half of the amount, so the fee mechasim won't bother this test
        uint256 redeemShares = initialShares / 2; 

        // Give it some time and let the yield grow
        skip(60*60*24*100);

        uint256 userChillSharesBefore = chill.balanceOf(address(this));
        uint256 chillTotalAssetsBefore = chill.totalAssets();

        // Redeem shares
        chill.approve(address(chill), type(uint256).max);
        asset.approve(address(chill), type(uint256).max);
        uint256 assets = chill.redeem(redeemShares, address(this), address(this));

        uint256 chillTotalAssetsAfter = chill.totalAssets();
        uint256 userChillSharesAfter = chill.balanceOf(address(this));        

        // Check that assets were redeemed
        assert(assets > 0);
        assert(chillTotalAssetsAfter == chillTotalAssetsBefore - assets);

        // Sean: Weak check in the assertion without quantifying the delta, because
        //      the amount of shares burned may be different than the amount specified to 
        //      redeem, due to the pricing mechanism of Hyperdrive LP.
        assert(userChillSharesAfter < userChillSharesBefore);
    }

    function testSetServiceFeeBpsAsOperator() public {
        // Set the service fee as the operator
        vm.prank(operator); // Simulate the operator calling the function
        chill.setServiceFeeBps(2000); // Set to 20%

        // Verify that the service fee was set correctly
        assert(chill.serviceFeeBps() == 2000);
    }

    function testSetServiceFeeBpsAsNonOperator() public {
        // Attempt to set the service fee as a non-operator
        address nonOperator = address(0x456); // Replace with a valid non-operator address
        vm.prank(nonOperator); // Simulate the non-operator calling the function

        // Expect the call to revert
        vm.expectRevert("LPAndChill: invalid role for the caller");
        chill.setServiceFeeBps(2000); // Attempt to set to 20%
    }

    function testWithdrawFeeAsOperator() public {
        // fee 10%
        vm.prank(operator); 
        chill.setServiceFeeBps(1000); 


        asset.approve(address(chill), type(uint256).max);
        testWithdraw();

        uint256 feeBalance = asset.balanceOf(address(chill.feeVault()));

        // withdraw the fees as operator
        uint256 balanceBefore = asset.balanceOf(address(operator));
        vm.startPrank(operator); 
        IVault(chill.feeVault()).withdrawERC20(address(asset), feeBalance, address(operator));
        vm.stopPrank();
        uint256 balanceAfter = asset.balanceOf(address(operator));

        // verify the balance change
        assert(balanceAfter == balanceBefore + feeBalance);
    }

    function testWithdrawFeeAsNonOperator() public {
        // fee 10%
        vm.prank(operator); 
        chill.setServiceFeeBps(1000); 


        asset.approve(address(chill), type(uint256).max);

        uint256 feeBalanceBefore = asset.balanceOf(address(chill.feeVault()));
        testWithdraw();

        uint256 feeBalanceAfter = asset.balanceOf(address(chill.feeVault()));

        assert(feeBalanceBefore == 0);
        assert(feeBalanceAfter > feeBalanceBefore);
        
        // when a non-operator tries to withdraw the fee
        address nonOperator = address(0x111); 
        IVault feeVault = IVault(chill.feeVault());
        vm.prank(nonOperator); 
        vm.expectRevert("feeVault: invalid role for the caller"); 
        feeVault.withdrawERC20(address(asset), feeBalanceAfter, address(nonOperator));
    }
}