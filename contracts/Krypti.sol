pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Krypti is ERC20Capped, Ownable {
	
	uint256 public releaseDate;
	mapping (address => bool) public frozenacc;

	event FroxenFunds(address target, bool frozen);

	constructor(
		address _ownerAddress
	)

	ERC20("Krypti", "KRPT")
	ERC20Capped(1000000)
	public{
		_setupDecimals(0);
		 _mint(_ownerAddress, 1000000);
		releaseDate  = block.timestamp;
	}

	function freezeAccount(address target, bool freeze) public onlyOwner() {
		frozenacc[target] = freeze;
		emit FroxenFunds(target, freeze);
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
				require(!frozenacc[msg.sender], "El usuario tiene congelados sus fondos");
    }

}