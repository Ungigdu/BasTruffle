pragma solidity >= 0.5.0;

import "./ERC20.sol";
import "./owned.sol";

contract SendFreeBas{

    ERC20 public token;

    mapping(address=>bool) public applyRecord;

    constructor(address t) public {
        token = ERC20(t);
    }

    function SendTokenByContract(address to, uint256 amount) external {
        require(applyRecord[to]==false,"already applied");
        token.transferFrom(msg.sender,to,amount);
        applyRecord[to] = true;
    }
}
