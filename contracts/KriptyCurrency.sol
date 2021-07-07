import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract KriptyCoin is ERC20Capped, Ownable {
	
	uint256 public releaseDate;
	mapping (address => bool) public excludedAcc;
	mapping (address => uint) public claimedTokensFromPool;
	uint private _txFeeStacking;
	uint private _liqFee;
	uint256 _precision = 1*10**18;
	uint private capToken;
	address kriptyGovToken;
	function stacking() public view returns (uint) { return _txFeeStacking; }
	function networkFee() public view returns (uint) { return _liqFee; }




	constructor(
		//address _ownerAddress, ver para que lo usabamos
		address _burnAddress,
		address _devTeam,
		address _airDrop,
		uint liqFee
	)

	ERC20("KriptyCoin", "KRCO")
	ERC20Capped(1000000000000000)
	public{
		_setupDecimals(0);
		_mint(address(this), 525000000000000);
		_mint(_burnAddress, 400000000000000);
		_mint(_devTeam, 25000000000000);
		_mint(_airDrop, 50000000000000);
		_liqFee = liqFee;
		releaseDate  = block.timestamp;
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		//unit tx_balances[msg.sender]
		//TODO: verificar no se pueda cobrar rewards de mas

		if(!excludedAcc[msg.sender] || !excludedAcc[recipient]){
			uint txFee = SafeMath.div(SafeMath.mul(amount, _liqFee), 100);
			_burn(msg.sender, txFee);
			amount-= txFee; //no se debia hacer burn, sino quitar el dinero al monto transferido
			_txFeeStacking += txFee/2;
				
		}
		
		//Se transfiere para que baje el balance antes de hacer los calculos correspondientes
		//Se calcula el reward en base al nuevo balance
		//Se agrega en el mapping la reward reclamada
		//Se queman los tokens equivalentes al reward del contrato
		//Y se crean nuevos tokens equivalentes en la cuenta de quien recive el reward
		super._transfer(_msgSender(), recipient, amount*capToken);
		uint txRewards = (balanceOf(msg.sender) * _txFeeStacking) / _precision;
		claimedTokensFromPool[msg.sender] += txRewards;
		
		//_burn(address(this), txRewards);
		_mint(msg.sender, txRewards);

        return true;
    }
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20Capped) {
		super._beforeTokenTransfer(from, to, amount);	
    }

	// function _txBurn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");
    //     _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    //     _totalSupply = _totalSupply.sub(amount);
    // }

	function _setSwapExclude(address swapPair) public onlyOwner(){
		excludedAcc[swapPair] = true;
	}

	function capTokenSupply(uint decimals) public onlyOwner(){
		//solo puede ser 1, 10, 100, 1000, ...
		//_totalSupply /= decimals;
		//_txFeeStacking /= decimals;
		capToken = decimals;
	}

	function setKriptyGovToken(address kriptyAddress) public onlyOwner(){
		kriptyGovToken = kriptyAddress;
	}

	function increaseBalance(uint amount) public{
		require(msg.sender == kriptyGovToken, "Only Kripty token can call this function");
		_txFeeStacking += amount;
	}

	//function claimTokens(uint amount) public onlyOwner() {
	//	(bool success, ) = owner.call{vaue: address(this).balance}("");
	//	require(success, "");
	//}

	function  balanceOf(address account) public view override returns (uint256){
		uint ownerBalance = super.balanceOf(account);
		uint txRewards = (ownerBalance * _txFeeStacking) / _precision;//aun no esta bien, problema en presition si se hace cap
		if(txRewards/capToken >= 1){
			return (ownerBalance + txRewards)/capToken;
		}else{
			return ownerBalance/capToken;
		}
		
	}
	
}