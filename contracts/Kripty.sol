pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Kripty is ERC20Capped, ERC20Burnable, Ownable {
	
	uint256 public releaseDate;
	KriptyCoinInterface public KriptyCoin;
	mapping (address => bool) public frozenacc;
	mapping (address=>bool) private excludeFromFee;
	uint private capToken = 1;

	event FrozenFunds(address target, bool frozen);

	constructor(
		address _ownerAddress,
		address _escrow,
		address _kriptyCoin
	)

	ERC20("Kripty Governance Token", "KTY")
	ERC20Capped(1000000000000000)
	public{
		_setupDecimals(0);
		 _mint(_ownerAddress, 400000000000000);
		 _mint(_escrow, 600000000000000);
		releaseDate  = block.timestamp;
		excludeFromFee[_kriptyCoin] = true;
		KriptyCoin = KriptyCoinInterface(_kriptyCoin);
	}

	function freezeAccount(address target, bool freeze) public onlyOwner() {
		frozenacc[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		if(!excludeFromFee[msg.sender] || !excludeFromFee[recipient]){
			uint txLFee = SafeMath.div(SafeMath.mul(amount, 10), 100);
			_burn(msg.sender, txLFee);
			KriptyCoin.increaseBalance(txLFee/2);
		}


        super._transfer(_msgSender(), recipient, amount*capToken);
        return true;
    }

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
				require(!frozenacc[msg.sender], "Frozen funds to this user");
    }

	function _setSwapExclude(address swapPair) public onlyOwner(){
		excludeFromFee[swapPair] = true;
	}
	
	function capTokenSupply(uint decimals) public onlyOwner(){
		//_totalSupply = _totalSupply/x;
		capToken = decimals;
	}

	function balanceOf(address account) public view override returns (uint256){
		return super.balanceOf(account)/capToken;
	}

	function burn(address account, uint amount) public onlyOwner() {
		_burn(account, amount);
	}

	function mint(address account, uint amount) public onlyOwner() {
		_mint(account, amount);
	}
	
}

interface KriptyCoinInterface {
        function increaseBalance(uint amount) external;
}