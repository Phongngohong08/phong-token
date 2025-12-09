// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 1. Imports
import {Test, console} from "forge-std/Test.sol";
import {ProToken} from "./ProToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// 2. Test contract declaration
contract ProTokenTest is Test {
    
    // 3. State variables
    ProToken public token;
    
    address public admin;      // Deployer, has all roles initially
    address public user1;      // A random user
    address public user2;      // Another random user

    uint256 public constant INITIAL_SUPPLY = 1 * 10**18;

    // 4. setUp function (runs before each test case)
    function setUp() public {
        // Create addresses for easy management
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy contract as 'admin'
        vm.prank(admin);
        token = new ProToken();
    }

    //-------------------------------------------------
    // Test 1: Initial State
    //-------------------------------------------------
    
    function test_InitialState() public view {
        assertEq(token.name(), "ProToken", "Token name is incorrect");
        assertEq(token.symbol(), "PRT", "Token symbol is incorrect");
        assertEq(token.decimals(), 18, "Decimals is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Initial total supply is incorrect");
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY, "Admin balance is incorrect");
    }

    function test_InitialRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin), "Admin missing DEFAULT_ADMIN_ROLE");
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin), "Admin missing MINTER_ROLE");
        assertTrue(token.hasRole(token.BURNER_ROLE(), admin), "Admin missing BURNER_ROLE");
    }

    //-------------------------------------------------
    // Test 2: Mint Functionality
    //-------------------------------------------------

    function test_Mint_Success() public {
        uint256 mintAmount = 100 ether;
        
        // Admin (has MINTER_ROLE) mints to user1
        vm.prank(admin);
        token.systemMint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount, "User1 balance after mint is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount, "Total supply after mint is incorrect");
    }

    function test_Mint_Fail_NotMinter() public {
        // User1 (doesn't have MINTER_ROLE) tries to mint
        vm.prank(user1);

        // Expect revert from AccessControl
        vm.expectRevert();
        token.systemMint(user2, 100 ether);
    }

    //-------------------------------------------------
    // Test 3: Burn Functionality
    //-------------------------------------------------

    function test_SystemBurn_Success() public {
        uint256 burnAmount = 0.5 ether;

        // Admin (has BURNER_ROLE) burns tokens from their own account
        vm.prank(admin);
        token.systemBurn(admin, burnAmount);

        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - burnAmount, "Admin balance after burn is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount, "Total supply after burn is incorrect");
    }

    function test_SystemBurn_Fail_NotBurner() public {
        // Admin mints to user1
        vm.prank(admin);
        token.systemMint(user1, 100 ether);

        // User1 (has tokens but no BURNER_ROLE) tries to burn
        vm.prank(user1);

        vm.expectRevert();
        token.systemBurn(user1, 50 ether);
    }

    function test_SystemBurn_FromAnotherAccount() public {
        // Admin mints to user1
        vm.prank(admin);
        token.systemMint(user1, 100 ether);

        uint256 burnAmount = 50 ether;

        // Admin (has BURNER_ROLE) can burn tokens from user1
        vm.prank(admin);
        token.systemBurn(user1, burnAmount);

        assertEq(token.balanceOf(user1), 100 ether - burnAmount, "User1 balance after burn is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 100 ether - burnAmount, "Total supply after burn is incorrect");
    }

    //-------------------------------------------------
    // Test 4: SystemTransfer with 1% Burn
    //-------------------------------------------------

    function test_SystemTransfer_Success() public {
        // Admin mints to user1
        vm.prank(admin);
        token.systemMint(user1, 100 ether);

        uint256 transferAmount = 100 ether;
        uint256 burnAmount = transferAmount / 100; // 1%
        uint256 receiveAmount = transferAmount - burnAmount; // 99%

        // Admin (has DEFAULT_ADMIN_ROLE) transfers from user1 to user2
        vm.prank(admin);
        token.systemTransfer(user1, user2, transferAmount);

        assertEq(token.balanceOf(user1), 0, "User1 balance after transfer is incorrect");
        assertEq(token.balanceOf(user2), receiveAmount, "User2 should receive 99%");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 100 ether - burnAmount, "Total supply should decrease by 1%");
    }

    function test_SystemTransfer_Fail_NotAdmin() public {
        // Admin mints to user1
        vm.prank(admin);
        token.systemMint(user1, 100 ether);

        // User1 (doesn't have DEFAULT_ADMIN_ROLE) tries to use systemTransfer
        vm.prank(user1);

        vm.expectRevert();
        token.systemTransfer(user1, user2, 50 ether);
    }

    function test_SystemTransfer_BurnCalculation() public {
        // Admin mints to user1
        vm.prank(admin);
        token.systemMint(user1, 1000 ether);

        uint256 transferAmount = 1000 ether;
        uint256 expectedBurn = 10 ether; // 1% of 1000
        uint256 expectedReceive = 990 ether; // 99% of 1000

        uint256 totalSupplyBefore = token.totalSupply();

        // Admin transfers
        vm.prank(admin);
        token.systemTransfer(user1, user2, transferAmount);

        assertEq(token.balanceOf(user2), expectedReceive, "User2 should receive exactly 99%");
        assertEq(token.totalSupply(), totalSupplyBefore - expectedBurn, "Total supply should decrease by 1%");
    }

    //-------------------------------------------------
    // Test 5: Role Management
    //-------------------------------------------------

    function test_GrantRole_Success() public {
        // Admin (has DEFAULT_ADMIN_ROLE) grants MINTER_ROLE to user1
        vm.prank(admin);
        token.grantMinterRole(user1);

        assertTrue(token.hasRole(token.MINTER_ROLE(), user1), "Grant minter role failed");
    }

    function test_GrantRole_Fail_NotAdmin() public {
        // User1 (doesn't have DEFAULT_ADMIN_ROLE) tries to grant role to user2
        vm.prank(user1);

        vm.expectRevert();
        token.grantMinterRole(user2);
    }

    function test_RevokeRole_Success() public {
        // Admin grants role to user1
        vm.prank(admin);
        token.grantMinterRole(user1);
        assertTrue(token.hasRole(token.MINTER_ROLE(), user1), "Grant role failed");

        // Admin revokes role from user1
        vm.prank(admin);
        token.revokeMinterRole(user1);
        assertFalse(token.hasRole(token.MINTER_ROLE(), user1), "Revoke role failed");
    }
}