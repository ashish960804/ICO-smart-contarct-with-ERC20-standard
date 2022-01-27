// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustomToken{
    mapping(address => uint256) public _balances;
    mapping(address => mapping (address => uint256)) private _allowances;

    string private _name;   
    string private _symbol;
    uint256 _decimals;
    uint256 _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint256 decimalsUints) public {
        _balances[msg.sender] = initialSupply;
        _totalSupply = initialSupply;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = decimalsUints;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint256){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function setTotalSupply(uint256 totalAmount) internal{
        _totalSupply = totalAmount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account ,uint256 balance) internal {
        _balances[account] = balance;
    }

    function transfer(address beneficiary,uint256 amount) public returns (bool) {
        require(beneficiary != address(0), "Beneficiary address could not be zero");
        require(_balances[msg.sender] >= amount, "Sender doen't have enough balance");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Amount addition overflow");
        _balances[msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(msg.sender, beneficiary, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success){
        require(spender != address(0), "Spender address cann't be zero");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    function transferFrom(address sender, address beneficiary, uint256 amount) public returns (bool) {
        require(sender != address(0), "Sender address cannot be zero");
        require(beneficiary != address(0), "Beneficiary address could not be zero"); 
        require(amount <= _allowances[sender][msg.sender], "Allowances is not enough");
        require(_balances[sender] >= amount, "Sender doesn't have enough balance");
        require(_balances[beneficiary] + amount > _balances[beneficiary], "Amount addition overflow");

        _balances[sender] -= amount;
        _allowances[sender][msg.sender] -= amount;
        _balances[beneficiary] += amount;
        emit Transfer(sender, beneficiary, amount);
        return true;
    }
}

contract Configurable {
    uint256 public constant _toatlcapacity = 100000000*10**18;
    uint256 public constant basePrice = 100*10**18;
    uint256 public tokensSold = 0;
    
    uint256 public constant _reserve = 1000000*10**18;
    uint256 public remainingTokens = 0;
}

contract IcoToken is CustomToken, Configurable {
     enum Stages {
        none,
        icoStartdate, 
        icoEnddate
    }
    
    Stages currentStage;
  
    constructor() public {
        currentStage = Stages.none;
        _balances[msg.sender] += _reserve;
        _totalSupply += _reserve;
        remainingTokens = _toatlcapacity;
        emit Transfer(address(this), msg.sender, _reserve);
    }
    
    function tokentransfer() public payable {
        require(currentStage == Stages.icoStartdate, "Date is outside the ICO date");
        require(msg.value > 0, " Amount should be greater than zero");
        require(remainingTokens > 0 , "Token is sold out");
        
        
        uint256 weiAmount = msg.value; 
        uint256 tokens = weiAmount*basePrice/(1 ether);
        uint256 returnWei = 0;
        
        if(tokensSold+tokens > _toatlcapacity){
            uint256 newTokens = _toatlcapacity - tokensSold;
            uint256 newWei = newTokens/basePrice *(1 ether);
            returnWei = weiAmount - newWei;
            weiAmount = newWei;
            tokens = newTokens;
        }
        
        tokensSold = tokensSold + tokens; 
        remainingTokens = _toatlcapacity - tokensSold;
        if(returnWei > 0){
            transfer(msg.sender,returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
        _balances[msg.sender] = _balances[msg.sender] + tokens;
        emit Transfer(address(this), msg.sender, tokens);
        _totalSupply = _totalSupply +tokens ;
        transfer(msg.sender,weiAmount);
    }
    

    function startIco() public {
        require(currentStage != Stages.icoEnddate, "Date is outside the ICO date");
        currentStage = Stages.icoStartdate;
    }
    
    function endIco() public returns (bool) {
        currentStage = Stages.icoEnddate;
        if(remainingTokens > 0)
            _balances[msg.sender] = _balances[msg.sender] + remainingTokens;
        transfer(msg.sender,_balances[msg.sender]); 
    }

    function finalizeIco() public {
        require(currentStage != Stages.icoEnddate, "Date is outside the ICO date");
        endIco();
    }
    
}
