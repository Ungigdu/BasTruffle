pragma solidity >= 0.5.0;

import "./ERC20.sol";

contract BasToken is ERC20{

    string  public constant  name = "BlockChain Addressing System Token";
    string  public constant  symbol = "BAS";
    uint8   public constant  decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 4.2e8 * (10 ** uint256(decimals));

    constructor() public{
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function burn(uint amount) external{
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint amount) external{
        _burnFrom(account, amount);
    }
}