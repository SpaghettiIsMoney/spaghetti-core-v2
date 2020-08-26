pragma solidity ^0.5.12;

interface DSTokenAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

interface PASTA {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function setFoodbank(address _foodbank) external;
    function setGovernance(address _governance) external;
}

contract ChefsTable {

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // gov token
    DSTokenAbstract IOU;
    // token contract
    PASTA spaghetti;

    mapping(address=>uint) public balances;

    struct Proposal {
        uint id;
        address proposer;
        mapping(address => uint) forVotes;
        mapping(address => uint) againstVotes;
        uint totalForVotes;
        uint totalAgainstVotes;
        uint start; // block start;
        uint end;   // start + period
        address newFood;
        address newGov;
    }

    mapping(address => uint) public voteLock;
    mapping (uint => Proposal) public proposals;
    uint public proposalCount;
    uint public period = 17280; // voting period in blocks ~ 17280 3 days for 15s/block
    uint public lock = 17280;   // vote lock in blocks ~ 17280 3 days for 15s/block
    uint public minimum = 1e18; // you need 1 PASTA to propose

    constructor(address _spaghetti, address _iou) public {
        spaghetti = PASTA(_spaghetti);
        IOU = DSTokenAbstract(_iou);
    }

    function join(uint amount) public {
        uint bal = spaghetti.balanceOf(address(this));
        require(spaghetti.transferFrom(msg.sender, address(this), amount), "join/transferFrom-fail");
        require(iou.mint(spaghetti.balanceOf(address(this)) - bal), "join/mint-failed");
        balances[msg.sender] += spaghetti.balanceOf(address(this)) - bal;
    }

    function free(uint amount) public {
        require(voteLock[msg.sender] < block.number);
        require(iou.burn(msg.sender, amount), "free/burn-failed");
        require(spaghetti.transfer(msg.sender, amount), "free/transfer-failed");
    }

    function propose(address _newFood, address _newGov) public {
        require(balances[msg.sender] > minimum, "<minimum");
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.number,
            end: add(block.number, period),
            newFood: _newFood,
            newGov: _newGov
        });

        voteLock[msg.sender] = add(block.number, lock);
    }

    function voteFor(uint id) public {
        require(proposals[id].start < block.number , "<start");
        require(proposals[id].end > block.number , ">end");
        uint votes = sub(balances[msg.sender], proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = add(votes, proposals[id].totalForVotes);
        proposals[id].forVotes[msg.sender] = balances[msg.sender];

        voteLock[msg.sender] = add(block.number, lock);
    }

    function voteAgainst(uint id) public {
        require(proposals[id].start < block.number , "<start");
        require(proposals[id].end > block.number , ">end");
        uint votes = sub(balances[msg.sender], proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = add(votes, proposals[id].totalAgainstVotes);
        proposals[id].againstVotes[msg.sender] = balances[msg.sender];

        voteLock[msg.sender] = add(block.number, lock);
    }

    function execute(uint id) public {
        // If the proposal is over, has passed, and has passed a 3 day pause 
        if ((proposals[id].end + lock) < block.number && proposals[id].totalForVotes > proposals[id].totalAgaistVotes) {
            if (proposals[id].newFood != address(0)) {
                spaghetti.setFoodbank(proposals[id].newFood);
            }
            if (proposals[id].newGov != address(0)) {
                spaghetti.setGovernance(proposals[id].newGov);
            }
        }
    }

}
