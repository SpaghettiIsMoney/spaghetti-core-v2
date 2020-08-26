pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Pastav2.sol";
import "./ChefsTable.sol";
import "./iou.sol";

contract Pastav2Test is DSTest {
    Pastav2 pastav;

    function setUp() public {
        pastav = new Pastav2();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
