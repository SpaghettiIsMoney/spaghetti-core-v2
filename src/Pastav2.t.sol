pragma solidity ^0.5.0;

import "ds-test/test.sol";

import "./Pastav2.sol";
import "./ChefsTable.sol";
import "./iou.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
}

contract Pastav2Test is DSTest {
    Hevm hevm;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE = bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    Pastav2 pasta;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        pasta = new Pastav2();
        hevm.store(
            address(pasta),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(999999999999 ether))
        );
    }

    function test_transfer() public {
        pasta.transfer(address(0), 100);
        assertEq(pasta.balanceOf(address(0)), 98);
    }
}
