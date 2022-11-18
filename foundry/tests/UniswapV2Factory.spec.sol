pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../UniswapV2Factory.sol";
import "../ERC20.sol";
import "../UniswapV2Pair.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract TestFactory is Test {
    UniswapV2Factory factory;
    address wallet;
    address other = address(0);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    ERC20 tokenA;
    ERC20 tokenB;

    function setUp() public {
        factory = new UniswapV2Factory(address(this));
        wallet = address(this);
        tokenA = new ERC20(10000 ether);
        tokenB = new ERC20(10000 ether);
    }

    function testFeeInfo() public {
        assertEq(factory.feeTo(), address(0));
        assertEq(factory.feeToSetter(), wallet);
        assertEq(factory.allPairsLength(), 0);
    }

    function createPair(address tokenX, address tokenY) private {
        (address token0, address token1) = tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(factory), salt, keccak256(type(UniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );
        vm.expectEmit(true, true, false, true, address(factory));
        emit PairCreated(token0, token1, predictedAddress, 1);
        address pair = factory.createPair(tokenX, tokenY);

        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        factory.createPair(token0, token1);
        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        factory.createPair(token1, token0);

        assertEq(factory.getPair(token0, token1), predictedAddress);
        assertEq(factory.getPair(token1, token0), predictedAddress);
        assertEq(factory.allPairs(0), predictedAddress);
        assertEq(factory.allPairsLength(), 1);

        IUniswapV2Pair pairCon = IUniswapV2Pair(pair);
        assertEq(pairCon.factory(), address(factory));
        assertEq(pairCon.token0(), token0);
        assertEq(pairCon.token1(), token1);
    }

    function testCreatePair() public {
        createPair(address(tokenA), address(tokenB));
    }

    function testCreatePairReverse() public {
        createPair(address(tokenB), address(tokenA));
    }

    function testSetFeeTo() public {
        vm.expectRevert("UniswapV2: FORBIDDEN");
        vm.prank(other);
        factory.setFeeTo(other);

        factory.setFeeTo(wallet);
        assertEq(factory.feeTo(), wallet);
    }

    function testSetFeeToSetter() public {
        vm.expectRevert("UniswapV2: FORBIDDEN");
        vm.prank(other);
        factory.setFeeToSetter(other);

        factory.setFeeToSetter(other);
        assertEq(factory.feeToSetter(), other);

        vm.expectRevert("UniswapV2: FORBIDDEN");
        factory.setFeeToSetter(other);
    }
}
