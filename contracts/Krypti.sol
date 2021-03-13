pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

contract Krypti is ERC20Capped {
	
	uint256 public releaseDate;

	constructor(
		address _ownerAddress
	)

	ERC20("Krypti", "KRPT")
	ERC20Capped(100000)
	public{
		_setupDecimals(0);
		 _mint(_ownerAddress, 100000);
		releaseDate  = block.timestamp;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }

}