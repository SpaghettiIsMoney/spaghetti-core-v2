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

    SpaghettiTokenV2 pasta;
    ChefsTable gov;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        pasta = new SpaghettiTokenV2();
        gov = new ChefsTable(address(pasta));
        pasta.setGovernance(address(gov));
        hevm.store(
            address(pasta.pastav1()),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(1000000000000000000000))
        );
    }

    function test_full_logic_gov_pass() public {
        pasta.pastav1().approve(address(pasta));
        pasta.mint();
        assertEq(pasta.balanceOf(address(this)), 1000000000000000000000);
        pasta.transfer(address(0), 100000000000000000000);
        assertEq(pasta.balanceOf(address(0)), 98000000000000000000);
        assertEq(uint256(pasta.oven()), 1000000000000000000);
        assertEq(uint256(pasta.food()), 1000000000000000000);
        uint totalSup = pasta.totalSupply();
        pasta.burn();
        assertEq(pasta.totalSupply(), totalSup - 1000000000000000000);
        pasta.approve(address(gov));
        gov.join(100000000000000000000);
        gov.propose(address(this), address(this));
        hevm.warp(now + 1 days);
        gov.voteFor(0);
        hevm.warp(now + 7 days);
        gov.execute(0);
        assertEq(pasta.foodbank(), address(this));
        assertEq(pasta.governance(), address(this));
        gov.free(gov.balances(address(this)));
        uint256 currentFood = uint256(pasta.food());
        uint256 bal = pasta.balanceOf(pasta.foodbank());
        pasta.give();
        assertEq(pasta.balanceOf(pasta.foodbank()), bal + currentFood);
    }

    function testFail_full_logic_gov_fail() public {
        pasta.pastav1().approve(address(pasta));
        pasta.mint();
        assertEq(pasta.balanceOf(address(this)), 1000000000000000000000);
        pasta.transfer(address(0), 100000000000000000000);
        assertEq(pasta.balanceOf(address(0)), 98000000000000000000);
        assertEq(uint256(pasta.oven()), 1000000000000000000);
        assertEq(uint256(pasta.food()), 1000000000000000000);
        uint totalSup = pasta.totalSupply();
        pasta.burn();
        assertEq(pasta.totalSupply(), totalSup - 1000000000000000000);
        pasta.approve(address(gov));
        gov.join(100000000000000000000);
        gov.propose(address(this), address(this));
        hevm.warp(now + 1 days);
        gov.voteAgainst(0);
        hevm.warp(now + 7 days);
        gov.execute(0);
        assertEq(pasta.foodbank(), address(0));
        assertEq(pasta.governance(), address(gov));
        gov.free(gov.balances(address(this)));
        uint256 currentFood = uint256(pasta.food());
        uint256 bal = pasta.balanceOf(pasta.foodbank());
        pasta.give();
    }

}
