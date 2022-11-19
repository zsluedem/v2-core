pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../ERC20.sol";

contract UniswapV2ERC20Spec is Test {
    uint256 testNumber;
    ERC20 token;

    uint256 TEST_AMOUNT = 10 ether;
    uint256 TOTAL_SUPPLY = 10000 ether;
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

    address other = address(0);

    function setUp() public {
        token = new ERC20(TOTAL_SUPPLY);
    }

    function testBasic() public {
        assertEq(token.name(), "Uniswap V2");
        assertEq(token.symbol(), "UNI-V2");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 10000 ether);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit Approval(address(this), other, TEST_AMOUNT);
        token.approve(other, TEST_AMOUNT);
    }

    function testTransfer() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit Transfer(address(this), other, TEST_AMOUNT);
        token.transfer(other, TEST_AMOUNT);

        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    function testTransferFail() public {
        vm.expectRevert();
        token.transfer(other, TOTAL_SUPPLY + 1);
    }

    function testTransferFail2() public {
        vm.prank(other);
        vm.expectRevert();
        token.transfer(other, TEST_AMOUNT + 1);
    }

    function testTransferFrom() public {
        token.approve(other, TEST_AMOUNT);
        vm.prank(other);
        vm.expectEmit(true, true, true, true, address(token));
        emit Transfer(address(this), other, TEST_AMOUNT);
        token.transferFrom(address(this), other, TEST_AMOUNT);
        assertEq(token.allowance(address(this), other), 0);
        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    function testTransferFromMax() public {
        token.approve(other, MAX_INT);
        vm.prank(other);
        vm.expectEmit(true, true, true, true, address(token));
        emit Transfer(address(this), other, TEST_AMOUNT);
        token.transferFrom(address(this), other, TEST_AMOUNT);
        assertEq(token.allowance(address(this), other), MAX_INT);
        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY - TEST_AMOUNT);
        assertEq(token.balanceOf(other), TEST_AMOUNT);
    }

    function testPermit() public {
        uint256 nonce = token.nonces(address(this));
        uint256 deadline = MAX_INT;
    }
}
