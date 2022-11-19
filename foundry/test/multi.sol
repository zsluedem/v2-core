pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../ERC20.sol";

contract Call {
    event A(uint256 value);
    event B(uint256 value);

    function multi() public {
        emit A(1);
        emit B(2);
    }
}

contract UniswapV2ERC20Spec is Test {
    event A(uint256 value);
    event B(uint256 value);

    Call token;

    function setUp() public {
        token = new Call();
    }

    function testBasic() public {
        vm.expectEmit(false, false, false, true, address(token));
        emit A(1);
        vm.expectEmit(true, false, false, true, address(token));
        emit B(2);
        token.multi();
    }
}
