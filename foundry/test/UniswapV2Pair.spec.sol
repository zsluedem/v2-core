pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../UniswapV2Factory.sol";
import "../ERC20.sol";
import "../UniswapV2Pair.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract TestPair is Test {
    UniswapV2Factory factory;
    address wallet;
    address other = 0x7A2a0A4727a5dFAff55e130cECF5FD163C96012C;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    ERC20 token1;
    ERC20 token0;
    address pair;
    IUniswapV2Pair pairCon;
    IUniswapV2ERC20 pairErc;

    uint256 MINIMUM_LIQUIDITY = 10 ** 3;

    function setUp() public {
        factory = new UniswapV2Factory(address(this));
        wallet = address(this);
        token0 = new ERC20(10000 ether);
        token1 = new ERC20(10000 ether);
        pair = factory.createPair(address(token0), address(token1));
        pairErc = IUniswapV2ERC20(pair);
        pairCon = IUniswapV2Pair(pair);
    }

    function testMint() public {
        uint256 token0Amount = 1 ether;
        uint256 token1Amount = 4 ether;
        token0.transfer(pair, token0Amount);
        token1.transfer(pair, token1Amount);

        uint256 expectedLiquidity = 2 ether;

        vm.expectEmit(true, true, false, true, address(pair));
        emit Transfer(address(0), address(0), MINIMUM_LIQUIDITY);
        vm.expectEmit(true, true, false, true, address(pair));
        emit Transfer(address(0), wallet, expectedLiquidity - MINIMUM_LIQUIDITY);
        vm.expectEmit(true, false, false, true, address(pair));
        emit Sync(uint112(token0Amount), uint112(token1Amount));
        vm.expectEmit(true, true, true, true, address(pair));
        emit Mint(wallet, token0Amount, token1Amount);
        pairCon.mint(wallet);

        assertEq(pairErc.totalSupply(), expectedLiquidity);
        assertEq(pairErc.balanceOf(wallet), expectedLiquidity - MINIMUM_LIQUIDITY);
        assertEq(token0.balanceOf(pair), token0Amount);
        assertEq(token1.balanceOf(pair), token1Amount);

        (uint112 reToken0, uint112 reToken1, uint32 blockTime) = pairCon.getReserves();
        assertEq(reToken0, token0Amount);
        assertEq(reToken1, token1Amount);
    }

    function addLiquidity(uint256 token0Amount, uint256 token1Amount) private {
        token0.transfer(pair, token0Amount);
        token1.transfer(pair, token1Amount);
        pairCon.mint(wallet);
    }

    function swapCase(uint256 swapAmount, uint256 token0Amount, uint256 token1Amount, uint256 expectedOutputAmount)
        private
    {
        addLiquidity(token0Amount, token1Amount);
        token0.transfer(pair, swapAmount);
        vm.expectRevert();
        pairCon.swap(0, expectedOutputAmount + 1, wallet, bytes(""));

        pairCon.swap(0, expectedOutputAmount, wallet, bytes(""));
    }

    function optimisticCase(uint256 outputAmount, uint256 token0Amount, uint256 token1Amount, uint256 inputAmount)
        private
    {
        addLiquidity(token0Amount, token1Amount);
        token0.transfer(pair, inputAmount);
        vm.expectRevert();
        pairCon.swap(outputAmount + 1, 0, wallet, bytes(""));

        pairCon.swap(outputAmount, 0, wallet, bytes(""));
    }

    function testSwapCase1() public {
        swapCase(1 ether, 5 ether, 10 ether, 1662497915624478906);
    }

    function testSwapCase2() public {
        swapCase(1 ether, 10 ether, 5 ether, 453305446940074565);
    }

    function testSwapCase3() public {
        swapCase(2 ether, 5 ether, 10 ether, 2851015155847869602);
    }

    function testSwapCase4() public {
        swapCase(2 ether, 10 ether, 5 ether, 831248957812239453);
    }

    function testSwapCase5() public {
        swapCase(1 ether, 10 ether, 10 ether, 906610893880149131);
    }

    function testSwapCase6() public {
        swapCase(1 ether, 100 ether, 100 ether, 987158034397061298);
    }

    function testSwapCase7() public {
        swapCase(1 ether, 1000 ether, 1000 ether, 996006981039903216);
    }

    function testSwapCase8() public {
        optimisticCase(997000000000000000, 5 ether, 10 ether, 1 ether);
    }

    function testSwapCase9() public {
        optimisticCase(997000000000000000, 10 ether, 5 ether, 1 ether);
    }

    function testSwapCase10() public {
        optimisticCase(997000000000000000, 5 ether, 5 ether, 1 ether);
    }

    function testSwapCase11() public {
        optimisticCase(1 ether, 5 ether, 5 ether, 1003009027081243732);
    }

    function testSwapToken0() public {
        uint256 token0Amount = 5 ether;
        uint256 token1Amount = 10 ether;
        addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1 ether;
        uint256 expectedOutputAmount = 1662497915624478906;

        token0.transfer(pair, swapAmount);

        vm.expectEmit(true, true, false, true, address(token1));
        emit Transfer(pair, wallet, expectedOutputAmount);
        vm.expectEmit(true, false, false, true, pair);
        emit Sync(uint112(token0Amount + swapAmount), uint112(token1Amount - expectedOutputAmount));
        vm.expectEmit(true, true, false, true, pair);
        emit Swap(wallet, swapAmount, 0, 0, expectedOutputAmount, wallet);
        pairCon.swap(0, expectedOutputAmount, wallet, bytes(""));

        (uint112 reToken0, uint112 reToken1, uint32 blockTime) = pairCon.getReserves();
        assertEq(reToken0, token0Amount + swapAmount);
        assertEq(reToken1, token1Amount - expectedOutputAmount);
        assertEq(token0.balanceOf(pair), token0Amount + swapAmount);
        assertEq(token1.balanceOf(pair), token1Amount - expectedOutputAmount);
        assertEq(token0.totalSupply() - token0Amount - swapAmount, token0.balanceOf(wallet));
        assertEq(token1.totalSupply() - token1Amount + expectedOutputAmount, token1.balanceOf(wallet));
    }

    function testSwapToken1() public {
        uint256 token0Amount = 5 ether;
        uint256 token1Amount = 10 ether;
        addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1 ether;
        uint256 expectedOutputAmount = 453305446940074565;

        token1.transfer(pair, swapAmount);

        vm.expectEmit(true, true, false, true, address(token0));
        emit Transfer(pair, wallet, expectedOutputAmount);
        vm.expectEmit(true, false, false, true, pair);
        emit Sync(uint112(token0Amount - expectedOutputAmount), uint112(token1Amount + swapAmount));
        vm.expectEmit(true, true, false, true, pair);
        emit Swap(wallet, 0, swapAmount, expectedOutputAmount, 0, wallet);
        pairCon.swap(expectedOutputAmount, 0, wallet, bytes(""));

        (uint112 reToken0, uint112 reToken1, uint32 blockTime) = pairCon.getReserves();
        assertEq(reToken0, token0Amount - expectedOutputAmount);
        assertEq(reToken1, token1Amount + swapAmount);
        assertEq(token0.balanceOf(pair), token0Amount - expectedOutputAmount);
        assertEq(token1.balanceOf(pair), token1Amount + swapAmount);
        assertEq(token0.totalSupply() - token0Amount + expectedOutputAmount, token0.balanceOf(wallet));
        assertEq(token1.totalSupply() - token1Amount - swapAmount, token1.balanceOf(wallet));
    }

    function testBurn() public {
        uint256 token0Amount = 3 ether;
        uint256 token1Amount = 3 ether;
        addLiquidity(token0Amount, token1Amount);

        uint256 expectedLiquidity = 3 ether;
        pairErc.transfer(pair, expectedLiquidity - MINIMUM_LIQUIDITY);

        vm.expectEmit(true, true, false, true, pair);
        emit Transfer(pair, address(0), expectedLiquidity - MINIMUM_LIQUIDITY);
        vm.expectEmit(true, true, false, true, address(token0));
        emit Transfer(pair, wallet, token0Amount - 1000);
        vm.expectEmit(true, true, false, true, address(token1));
        emit Transfer(pair, wallet, token1Amount - 1000);
        vm.expectEmit(true, false, false, true, pair);
        emit Sync(1000, 1000);
        vm.expectEmit(true, false, false, true, pair);
        emit Burn(wallet, token0Amount - 1000, token1Amount - 1000, wallet);
        pairCon.burn(wallet);

        assertEq(pairErc.balanceOf(pair), 0);
        assertEq(pairErc.totalSupply(), MINIMUM_LIQUIDITY);
        assertEq(token0.balanceOf(pair), 1000);
        assertEq(token1.balanceOf(pair), 1000);
        assertEq(token0.balanceOf(wallet), token0.totalSupply() - 1000);
        assertEq(token1.balanceOf(wallet), token1.totalSupply() - 1000);
    }

    function testPrice01Cumulative() public {
        uint256 token0Amount = 3 ether;
        uint256 token1Amount = 3 ether;

        addLiquidity(token0Amount, token1Amount);

        (uint112 reToken0, uint112 reToken1, uint32 blockTime) = pairCon.getReserves();

        vm.warp(blockTime + 1);
        pairCon.sync();

        (uint256 initial1, uint256 initial2) = encodePrice(token0Amount, token1Amount);

        assertEq(initial1, pairCon.price0CumulativeLast());
        assertEq(initial2, pairCon.price1CumulativeLast());

        uint256 swapAmount = 3 ether;
        token0.transfer(pair, swapAmount);

        vm.warp(blockTime + 10);
        pairCon.swap(0, 1 ether, wallet, bytes(""));
        assertEq(pairCon.price0CumulativeLast(), initial1 * 10);
        assertEq(pairCon.price1CumulativeLast(), initial2 * 10);

        vm.warp(blockTime + 20);
        pairCon.sync();
        (uint256 initial3, uint256 initial4) = encodePrice(6 ether, 2 ether);
        assertEq(pairCon.price1CumulativeLast(), initial3 * 10 + initial1 * 10);
        assertEq(pairCon.price0CumulativeLast(), initial4 * 10 + initial2 * 10);
    }

    function testFeeToOff() public {
        uint256 token0Amount = 1000 ether;
        uint256 token1Amount = 1000 ether;
        addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1 ether;
        uint256 expectedOutputAmount = 996006981039903216;

        token1.transfer(pair, swapAmount);
        pairCon.swap(expectedOutputAmount, 0, wallet, bytes(""));

        uint256 expectedLiquidity = 1000 ether;
        pairErc.transfer(pair, expectedLiquidity - MINIMUM_LIQUIDITY);
        pairCon.burn(wallet);
        assertEq(pairErc.totalSupply(), MINIMUM_LIQUIDITY);
    }

    function testFeeToOn() public {
        factory.setFeeTo(other);

        uint256 token0Amount = 1000 ether;
        uint256 token1Amount = 1000 ether;
        addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1 ether;
        uint256 expectedOutputAmount = 996006981039903216;

        token1.transfer(pair, swapAmount);
        pairCon.swap(expectedOutputAmount, 0, wallet, bytes(""));

        uint256 expectedLiquidity = 1000 ether;
        pairErc.transfer(pair, expectedLiquidity - MINIMUM_LIQUIDITY);
        pairCon.burn(wallet);

        assertEq(pairErc.totalSupply(), MINIMUM_LIQUIDITY + 249750499251388);
        // assertEq(pairErc.balanceOf(other), 249750499251388);

        // assertEq(token0.balanceOf(pair), 1000 + 249501683697445);
        // assertEq(token1.balanceOf(pair), 1000 + 250000187312969);
    }

    function encodePrice(uint256 reserve1, uint256 reserve2) private returns (uint256 result1, uint256 result2) {
        result1 = reserve1 * (2 ** 112) / reserve2;
        result2 = reserve2 * (2 ** 112) / reserve1;
    }
}
