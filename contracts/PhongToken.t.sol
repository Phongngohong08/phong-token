// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 1. Imports
import {Test, console} from "forge-std/Test.sol";
import {PhongToken} from "./PhongToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// 2. Test contract declaration
contract PhongTokenTest is Test {
    
    // 3. State variables
    PhongToken public token;
    
    address public admin;      // Deployer, has all roles initially
    address public user1;      // A random user
    address public user2;      // Another random user

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    // 4. setUp function (runs before each test case)
    function setUp() public {
        // Create addresses for easy management
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy contract as 'admin'
        vm.prank(admin);
        token = new PhongToken();
    }

    //-------------------------------------------------
    // Test 1: Initial State
    //-------------------------------------------------
    
    function test_InitialState() public {
        assertEq(token.name(), "PhongToken", "Token name is incorrect");
        assertEq(token.symbol(), "PNT", "Token symbol is incorrect");
        assertEq(token.decimals(), 18, "Decimals is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Initial total supply is incorrect");
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY, "Admin balance is incorrect");
    }

    function test_InitialRoles() public {
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
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount, "User1 balance after mint is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount, "Total supply after mint is incorrect");
    }

    function test_Mint_Fail_NotMinter() public {
        // User1 (doesn't have MINTER_ROLE) tries to mint
        vm.prank(user1);

        // Expect revert from AccessControl
        vm.expectRevert();
        token.mint(user2, 100 ether);
    }

    //-------------------------------------------------
    // Test 3: Burn Functionality
    //-------------------------------------------------

    function test_Burn_Success() public {
        uint256 burnAmount = 50 ether;

        // Admin (has BURNER_ROLE and has tokens) burns their own tokens
        vm.prank(admin);
        token.burn(burnAmount);

        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - burnAmount, "Admin balance after burn is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount, "Total supply after burn is incorrect");
    }

    function test_Burn_Fail_NotBurner() public {
        // Admin mints to user1
        vm.prank(admin);
        token.mint(user1, 100 ether);

        // User1 (has tokens but no BURNER_ROLE) tries to burn
        vm.prank(user1);

        vm.expectRevert();
        token.burn(50 ether);
    }

    function test_BurnFrom_Success() public {
        uint256 burnAmount = 50 ether;
        // Admin mints to user1
        vm.prank(admin);
        token.mint(user1, 100 ether);

        // User1 approves admin (admin has BURNER_ROLE)
        vm.prank(user1);
        token.approve(admin, burnAmount);

        // Admin (is burner) burns tokens from user1
        vm.prank(admin);
        token.burnFrom(user1, burnAmount);

        assertEq(token.balanceOf(user1), 100 ether - burnAmount, "User1 balance after burnFrom is incorrect");
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 100 ether - burnAmount, "Total supply after burnFrom is incorrect");
    }

    function test_BurnFrom_Fail_NotBurner() public {
        // Admin mints to user1
        vm.prank(admin);
        token.mint(user1, 100 ether);

        // User1 approves user2 (user2 doesn't have BURNER_ROLE)
        vm.prank(user1);
        token.approve(user2, 50 ether);

        // User2 tries to burnFrom user1
        vm.prank(user2);
        
        vm.expectRevert();
        token.burnFrom(user1, 50 ether);
    }

    function test_BurnFrom_Fail_NoAllowance() public {
        // Admin mints to user1
        vm.prank(admin);
        token.mint(user1, 100 ether);

        // Admin (has BURNER_ROLE) tries to burnFrom user1 without approval
        vm.prank(admin);

        // Prepare to catch revert error from ERC20
        vm.expectRevert(abi.encodeWithSelector(
            IERC20Errors.ERC20InsufficientAllowance.selector, 
            admin, // spender
            0,     // allowance
            50 ether // needed
        ));
        
        token.burnFrom(user1, 50 ether);
    }

    //-------------------------------------------------
    // Test 4: Role Management
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