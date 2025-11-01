// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenPreSale is ERC20, Ownable {
    struct StepInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    bool public presaleIsActive;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public initialPrice;
    uint256 public regularSalePrice;
    uint256 public whitelist_capacity;
    uint256 public preSaleSteps;
    uint256 public minStakingAmount;
    uint256 public stakingRewardRate;
    uint256 public minUnstakingPeriod;
    uint256 public stakingRewardFrequency;
    uint256 public stepDuration;
    uint256 public referralTokenReward;
    uint256 public minTokensToBuy;
    uint256 public whiteListDiscount;

    uint public preSaleTokens;
    uint public publicSaleTokens;
    uint public teamTokens;
    uint public stakingRewardTokens;
    uint public ecoSystemGrowthTokens;
    uint public liquidityPoolTokens;
    uint public partnerShipsTokens;
    uint public reserveFundTokens;
    
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public stakingTimestamp;
    mapping(address => bool) public whitelist;
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralCounts;
    mapping(address => uint256) public balances;
    

    mapping(uint256 => StepInfo) public preSaleStepsInfo;
    event UserWhitelistedWithReferral(address indexed user, address indexed referral);
    event UserWhitelisted(address indexed user);
    event ReferralRewardMinted(address indexed referrer, uint256 rewardAmount);


    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 reward);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event PreSaleStarted(uint256 startTime, uint256 endTime);
    event PreSaleEnded(uint256 endTime);

    
    constructor(
        address initialOwner, 
        uint256 totalSupply, 
        uint256 _initialPrice, 
        uint256 _regularSalePrice, 
        uint256 _stakingRewardRate,
        uint256 _minUnstakingPeriod,
        uint256 _stakingRewardFrequency,
        uint256 _whitelist_capacity,
        uint256 _whiteListDiscount,
        uint256 _minTokensToBuy,
        uint256 _minStakingAmount ) 

        ERC20("NatureToken", "NTR") 
        Ownable(initialOwner) 
    {
        _mint(address(this), totalSupply );
        initialPrice = _initialPrice;
        regularSalePrice = _regularSalePrice;
        stakingRewardRate = _stakingRewardRate;
        presaleIsActive = false;
        minUnstakingPeriod  = _minUnstakingPeriod;
        stakingRewardFrequency = _stakingRewardFrequency;
        whitelist_capacity = _whitelist_capacity;
        whiteListDiscount=_whiteListDiscount;
        minTokensToBuy = _minTokensToBuy;
        minStakingAmount = _minStakingAmount;
        preSaleTokens= totalSupply /100 *10;
        publicSaleTokens = totalSupply  /100 *20;
        teamTokens= totalSupply  /100 *10;
        stakingRewardTokens= totalSupply  /100 *25;
        ecoSystemGrowthTokens= totalSupply  /100 *10;
        liquidityPoolTokens= totalSupply  /100 *10;
        partnerShipsTokens= totalSupply  /100 *5;
        reserveFundTokens= totalSupply  /100 *10;



    }

    

     function signUpForWhitelist() external {
        require(!whitelist[msg.sender], "Already whitelisted");
        require(whitelist_capacity>0,"White list is not possible anymore");
        whitelist[msg.sender] = true;
        whitelist_capacity-=1;
        emit UserWhitelisted(msg.sender );
    }
    function isWhiteListed() public view returns (bool){
        return whitelist[msg.sender];
    }
    function getMsgSender() public view returns (address){
        return msg.sender;
    }
    
    function signUpForWhitelistWithReferral(address referral) external {
        require(!whitelist[msg.sender], "Already whitelisted");
        require(msg.sender != referral, "Cannot refer yourself");
        require(whitelist_capacity>0,"White list is not possible anymore");
        whitelist[msg.sender] = true;
        whitelist_capacity-=1;

        if (referral != address(0) && whitelist[referral]) {
            referrals[msg.sender] = referral;
            referralCounts[referral] += 1;
        }
        
        emit UserWhitelistedWithReferral(msg.sender, referral);
    }
    function calculateReferralReward() public view returns (uint256) {

        return referralCounts[msg.sender] * 500;
    }

    function mintReferralReward() external {
            require(presaleIsActive==true,"Presale not started yet");
            uint256 rewardAmount = calculateReferralReward();
            require(rewardAmount > 0, "No rewards available");
            require(rewardAmount >= stakingRewardTokens,"Staking & Rewards pool is not enough to cover the reward");
            _mint(msg.sender, rewardAmount);
            referralCounts[msg.sender] = 0;
            emit ReferralRewardMinted(msg.sender, rewardAmount);
        }

    /**
     * @notice Start the pre-sale
     */
    function startPreSale(uint256 _startTime, uint256 _endTime, uint256 steps) external onlyOwner {
        // require(_startTime >= block.timestamp, "Start time must be in the future");
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
        preSaleSteps = steps;
        stepDuration = (_endTime - _startTime)/steps;
        presaleIsActive = true;
        uint256 priceIncrease = (regularSalePrice-initialPrice)/preSaleSteps;
        for (uint256 i = 0; i < steps; i++) {
            uint256 stepStartTime = _startTime + (i * stepDuration);
            uint256 stepEndTime = stepStartTime + stepDuration;

            preSaleStepsInfo[i] = StepInfo({
                startTime: stepStartTime,
                endTime: stepEndTime,
                price: initialPrice+(i*priceIncrease)
            });
        }

        emit PreSaleStarted(preSaleStartTime, preSaleEndTime);
    }


    function calculateStepsElapsed(uint256 startTime, uint256 endTime) public view returns (uint256) {
            require(endTime >= startTime, "End time must be after start time");
            uint256 stepsElapsed = (endTime - startTime) / stepDuration;
            return stepsElapsed;
        }
    function getCurrentStep() public view returns (uint256){
        require(block.timestamp >= preSaleStartTime, "End time must be after start time");
            uint256 stepsElapsed = (block.timestamp - preSaleStartTime) / stepDuration;
            return stepsElapsed;
    }
    function calculatePriceIncrease() public view returns (uint256){
        uint256 stepsElapsed =calculateStepsElapsed(preSaleStartTime, block.timestamp);
        uint256 priceIncrease = ((regularSalePrice - initialPrice) * stepsElapsed) / preSaleSteps;
        return priceIncrease;
    }


    
    function calculatePrice() public view returns (uint256) {
        require(presaleIsActive,"Pre-sale not started yet");
        bool isWhiteListed = whitelist[msg.sender];
        if ( block.timestamp > preSaleEndTime) {
            if (isWhiteListed){
            return regularSalePrice * (100-whiteListDiscount)/100;
            } else {
                return regularSalePrice;
            }
            
        }

        uint256 priceIncrease = calculatePriceIncrease();
        uint256 currentPrice = initialPrice+priceIncrease;
        
        if (isWhiteListed){
            currentPrice = currentPrice * (100-whiteListDiscount)/100;
        }
        return currentPrice;
    }

    
    function getTokensToBuy(uint256 msgValue) public view returns(uint256){
            uint256 currentPrice = calculatePrice();
            uint256 tokensToBuy = (msgValue) / currentPrice;
            return tokensToBuy;

    }
    /**
    * @notice Buy tokens during the presale or regular sale.
    */
    function buyTokens() external payable {
        require(presaleIsActive, "Sale not active.");
        require(msg.value > 0, "Must send ETH to buy tokens.");
        bool isPublicSale = block.timestamp > preSaleEndTime;

       

        uint256 currentPrice = calculatePrice(); // Call the calculatePrice function

        uint256 tokensToBuy = (msg.value) / currentPrice;
        require(tokensToBuy>=minTokensToBuy,"Please check mininum amount of tokens to buy");

         if (isPublicSale){
            require(publicSaleTokens>0,"Public sale tokens are terminated");
            require(publicSaleTokens>=tokensToBuy,"Not enough public sale tokens left");
        } else {
            require(preSaleTokens>0,"Presale tokens are terminated");
            require(preSaleTokens>=tokensToBuy,"Not enough presaletokens left");
        }


        require(balanceOf(address(this)) >= tokensToBuy, "Not enough tokens available.");
        balances[msg.sender] += tokensToBuy;
        _transfer(address(this), msg.sender, tokensToBuy);

        if (isPublicSale){
            publicSaleTokens -= tokensToBuy;
        }else{
            preSaleTokens -= tokensToBuy;
        }
      

        emit Transfer(address(this), msg.sender, tokensToBuy); // Emit transfer event
    }


    function getBalance() public view returns (uint256){
        return balanceOf(msg.sender);

    }

    

    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance.");
        require(amount >=minStakingAmount,"Min staking amount not respected");
        require(stakingRewardTokens>0,"Staking is not possible anymore");
        _transfer(msg.sender, address(this), amount);
        stakedAmount[msg.sender] += amount;
        stakingTimestamp[msg.sender] = block.timestamp;
        emit TokensStaked(msg.sender, amount);
    }

    function unstakeTokensWithReward() external {
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No tokens staked.");
        require(block.timestamp >= stakingTimestamp[msg.sender] + minUnstakingPeriod, "Unstake not possible yet");
        
        uint256 reward = calculateStakingReward();

        require(reward>=stakingRewardTokens,"Staking rewards tokens are not sufficient");
        stakedAmount[msg.sender] = 0;
        stakingTimestamp[msg.sender] = 0;

        _transfer(address(this), msg.sender, amount + reward);

        stakingRewardTokens-=reward;
        emit TokensUnstaked(msg.sender, amount, reward);
    }
    function unstakeTokensWithoutReward() external {
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No tokens staked.");
        require(block.timestamp >= stakingTimestamp[msg.sender] + minUnstakingPeriod, "Unstake not possible yet");
        
        stakedAmount[msg.sender] = 0;
        stakingTimestamp[msg.sender] = 0;

        _transfer(address(this), msg.sender, amount);
        emit TokensUnstaked(msg.sender, amount, 0);
    }

    function calculateStakingReward() public view returns (uint256) {
        uint256 periodsStaked = (block.timestamp - stakingTimestamp[msg.sender]) / stakingRewardFrequency;
        return (stakedAmount[msg.sender] * stakingRewardRate * periodsStaked) / 100;
    }

    function getStackedTokens() public view returns (uint256) {
            
            return stakedAmount[msg.sender];
    }

    function getStackingPeriod() public view returns (uint256) {
            
            return stakingTimestamp[msg.sender] + minUnstakingPeriod;
    }


    function setMinStakingAmount(uint256 _amount) external onlyOwner {
        minStakingAmount = _amount;
    }

    function setStakingRewardRate(uint256 _rate) external onlyOwner {
        stakingRewardRate = _rate;
    }

    function setMinUnstakingPeriod(uint256 _period) external onlyOwner {
        minUnstakingPeriod = _period;
    }

    function setStakingRewardFrequency(uint256 _frequency) external onlyOwner {
        stakingRewardFrequency = _frequency;
    }

    function setStepDuration(uint256 _duration) external onlyOwner {
        stepDuration = _duration;
    }

    function setReferralTokenReward(uint256 _reward) external onlyOwner {
        referralTokenReward = _reward;
    }

    function setMinTokensToBuy(uint256 _minTokens) external onlyOwner {
        minTokensToBuy = _minTokens;
    }

    function setWhiteListDiscount(uint256 _discount) external onlyOwner {
        whiteListDiscount = _discount;
    }
}