pragma solidity ^0.7.0;

import "./Kripty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KriptyEscrow is Ownable {
    
    mapping (address => uint256) private claimedTokens;
    uint private minUserAmount = 2500;
    uint private maxUserAmount = 2500000;

    Kripty public instance;

    constructor() public {
        
    }

    function initkripty(address tokenAddress) public {
        instance = Kripty(tokenAddress);
    }

    function claimTokens(uint256 amount) external {  //Falta modificador de  privacidad
        uint256 claimedTokensfrom  = claimedTokens[msg.sender];
        require(amount >= minUserAmount && instance.balanceOf(msg.sender) <= maxUserAmount, "Invalid amount");
        if (claimedTokensfrom < maxUserAmount && claimedTokensfrom + amount > maxUserAmount){
            amount = maxUserAmount - claimedTokensfrom;
        }
        instance.transfer(msg.sender, (amount - claimedTokensfrom));
        claimedTokens[msg.sender] = claimedTokensfrom + amount;
    }

    function withdraw() public onlyOwner() {
        instance.transfer(owner(), instance.balanceOf(address(this)));
    }

}
