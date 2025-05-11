// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/Escrow.sol";
import "../contracts/ERC20Mock.sol";

contract EscrowTest is Test {
    ERC20Mock token;
    Escrow escrow;

    address payer = address(0xA11ce);
    address payee = address(0xB0b);
    address arbiter = address(0xC0de);
    uint256 deposit = 1 ether;

    function setUp() public {
        token = new ERC20Mock();
        // mint tokens to payer
        token.mint(payer, deposit);
        // deploy escrow
        escrow = new Escrow(address(token), payer, payee, arbiter, deposit);
    }

    function testInitialState() public {
        assertEq(escrow.payer(), payer);
        assertEq(escrow.payee(), payee);
        assertEq(escrow.arbiter(), arbiter);
        assertEq(escrow.amount(), deposit);
        assertFalse(escrow.funded());
    }

    function testFundAndRelease() public {
        // fund
        vm.prank(payer);
        token.approve(address(escrow), deposit);
        vm.prank(payer);
        escrow.fund();
        assertTrue(escrow.funded());

        // release
        vm.prank(arbiter);
        escrow.release();
        assertTrue(escrow.released());
        assertEq(token.balanceOf(payee), deposit);
    }

    function testFundAndRefund() public {
        vm.prank(payer);
        token.approve(address(escrow), deposit);
        vm.prank(payer);
        escrow.fund();

        vm.prank(arbiter);
        escrow.refund();
        assertTrue(escrow.released());
        assertEq(token.balanceOf(payer), deposit);
    }

    function testFuzz_fund(uint128 amt) public {
        // restrict fuzzed deposit amount
        uint256 a = bound(amt, 1, type(uint256).max);
        // mint and approve
        token.mint(payer, a);
        vm.prank(payer);
        token.approve(address(escrow), a);
        // deploy fresh escrow for each fuzz
        Escrow e = new Escrow(address(token), payer, payee, arbiter, a);

        vm.prank(payer);
        e.fund();
        assertTrue(e.funded());
        assertEq(token.balanceOf(address(e)), a);
    }

    function testFuzz_release_notFunded(uint8 arbCfg) public {
        // arbCfg = 0: arbiter, else wrong actor
        address sender = arbCfg == 0 ? arbiter : address(0xFEED);
        vm.startPrank(sender);
        if (sender == arbiter) {
            vm.expectRevert("Not funded");
            escrow.release();
        } else {
            vm.expectRevert("Only arbiter");
            escrow.release();
        }
        vm.stopPrank();
    }
}