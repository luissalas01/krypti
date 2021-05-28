pragma solidity ^0.7.0;

import "./Kripty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KriptyEscrow is Ownable {
    
    mapping (address => uint256) private claimedTokens;
    uint private minUserAmount = 500000000;

    Kripty public instance;

    constructor() public {
        
    }

    function initkripty(address tokenAddress) public {
        instance = Kripty(tokenAddress);
    }

    function claimTokens(uint256 amount) external {
        uint256 claimedTokensfrom  = claimedTokens[msg.sender];
        require(amount >= minUserAmount , "Invalid amount");
        instance.transfer(msg.sender, (amount - claimedTokensfrom));
        claimedTokens[msg.sender] = claimedTokensfrom + amount;
    }

    function withdraw() public onlyOwner() {
        instance.transfer(owner(), instance.balanceOf(address(this)));
    }

}
