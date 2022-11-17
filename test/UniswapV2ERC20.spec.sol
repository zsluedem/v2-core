pragma solidity =0.5.16;

import "forge-std/Test.sol";
import "../contracts/UniswapV2ERC20.sol";

contract UniswapV2ERC20Spec is Test {
    uint256 testNumber;
    UniswapV2ERC20 swapErc20;

    uint256 TEST_AMOUNT = 10 ether;
    uint256 TOTAL_SUPPLY = 10000 ether;

    address other = address(0);

    function setUp() public {
        swapErc20 = new UniswapV2ERC20();
    }

    function testBasic() public {
        assertEq(swapErc20.name(), "Uniswap V2");
        assertEq(swapErc20.symbol(), "UNI-V2");
        assertEq(swapErc20.decimals(), 18);
        assertEq(swapErc20.totalSupply(), 10000 ether);
        assertEq(swapErc20.balanceOf(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84), TOTAL_SUPPLY);
    }

    function testApprove() public {
        vm.prank(other);
        vm.expectEmit(true, true, true, true, address(swapErc20));
        emit UniswapV2ERC20.Approval(other, address(swapErc20), Test_Amount);
        swapErc20.approve(other, TEST_AMOUNT);
    }
}
