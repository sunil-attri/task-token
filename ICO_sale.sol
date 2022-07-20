//SPDX-License-Identifier:UNLICENSED

import "./Token.sol";
pragma solidity >=0.6.0<=0.8.13;

contract TokenCrowdsale{

  AggregatorV3Interface internal priceFeed=AggregatorV3Interface(0x10b3c106c4ed7D22B0e7Abe5Dc43BdFA970a153c); //KOVAN TESTNET CHAINLINK PRICE_FEED ORACLE ETH_TO_USD
  address payable public admin;
  uint public decimals=18;
  string public description; 
  uint public timer;              // time when the tokenSale contract is deployed
  uint public timeAtStagePaused;  // time when the ICO is paused 
  uint public totalTimePaused;    // total paused time til the ICO is not stopped 
  uint public stoppedTimer;       // time when the ICO is stopped
  uint public fundRaised;         // total funds collected
  uint public tokenPrice;         
  int public ethToUsd;            // 
  uint public softCap=10**18*5000000/(uint(ethToUsd));
  uint public investorMinCap;   // $500 minimum investment
  uint public ethToUsdUpdater;  // timer for updating eth_to_usd in 7 days
  struct investorData{
        bool allowance;
        string investorName;
        uint investment;
    }

  address[] public investors; // investors who buyed token

  token public _token;
  mapping(address => investorData) public whiteList;
  mapping(CrowdSaleStage => uint) public bonusStructure;

  // Crowdsale Stages
  enum CrowdSaleStage{ PrivateICO, PreICO, fstWeek, scndWeek, thrdWeek, frthWeek}
  enum statusICO{ continued, pause, restarted, stopped}
  
  // Default to presale stage
  CrowdSaleStage public stage = CrowdSaleStage.PrivateICO;
  statusICO public status=statusICO.continued;

  event Sell(address indexed _buyer, uint256 _amount);

  constructor(token _tokenAddress){
    _token=token(_tokenAddress);
    timer=block.timestamp;
    ethToUsdUpdater=timer;
    admin=payable(msg.sender);
    (,ethToUsd,,,)=priceFeed.latestRoundData();  
    ethToUsd=ethToUsd/1e8;                // decimals=8 is given in chainlink oracle
    tokenPrice=1e15/(uint(ethToUsd));     // calculated $ 0.001 in wei
    description="Payment to be made in wei";
    investorMinCap = 10**18*500/(uint(ethToUsd));

  }

  
  function getInvestorContribution(address _investor) public view returns (uint256)
  {
    return whiteList[_investor].investment;
  }

  //update whitelist
  function updateWhiteList(address investorAddress,bool _allowance,string calldata _investorname) public onlyAdmin{
        //whiteList[investorAddress]=investorData({allowance:_allowance,investorName:_investorname}); //gas-inefficient
        whiteList[investorAddress].allowance=_allowance;
        whiteList[investorAddress].investorName=_investorname;

    }

    function setBonus() public onlyAdmin{
       bonusStructure[CrowdSaleStage.PrivateICO]=25;
       bonusStructure[CrowdSaleStage.PreICO]=20;
       bonusStructure[CrowdSaleStage.fstWeek]=15;
       bonusStructure[CrowdSaleStage.scndWeek]=10;
       bonusStructure[CrowdSaleStage.thrdWeek]=5;
       bonusStructure[CrowdSaleStage.frthWeek]=0;       
   }

   function updateEthToUsd() internal {
       if(block.timestamp>ethToUsdUpdater+7 days){
           (,ethToUsd,,,)=priceFeed.latestRoundData();  
           ethToUsd=ethToUsd/1e8;                        // decimals=8 is given in chainlink oracle
       }
   }

   function setCrowdsaleStage() public {
    stage=CrowdSaleStage((block.timestamp-timer-totalTimePaused)/(15 days));
    if(stage==CrowdSaleStage.fstWeek){
        stage=CrowdSaleStage((block.timestamp-timer+30)/(7 days));
    }
  }

  function calculateAmount(uint _numberOfTokens) internal returns(uint fees){      // Calculates fees for the token to be bought
      setCrowdsaleStage();
      updateEthToUsd();                                                            // Checks whether ethToUsd need to be Updated if yes then do
      fees=_numberOfTokens*(100-bonusStructure[stage])/100*1e15/(uint(ethToUsd));
  }

  modifier onlyAdmin(){
      require(msg.sender==admin,"Not Allowed");
      _;
  }

  modifier investingConditions(uint _numberOfTokens){                                                       
      uint fees=calculateAmount(_numberOfTokens);       
      require(status==statusICO.continued);             // Checks current status of ICO is continued or not
      require(whiteList[msg.sender].allowance,"Not Allowed to invest. First Get allowance in whiteList");   // Checks that whether the investor is allowed in whiteList or not
      require(_token.getBalance()>_numberOfTokens,"not enough tokens leftfor sale");   // Checks sufficient amount of tokens are left for sale or not
      if(_token.getBalance()*tokenPrice>1e18*500/(uint(ethToUsd)))
      require(fees>investorMinCap,"Minimum Investment Cap should be greater than USD 500");  //
      require(msg.value==fees);
      _;
  }

  function buy_Token(uint _numberOfTokens) external payable investingConditions(_numberOfTokens){     
      
      _token.transfer(msg.sender, _numberOfTokens);

      fundRaised += msg.value*(uint(ethToUsd));
      whiteList[msg.sender].investment += msg.value;
      investors.push(msg.sender);
      emit Sell(msg.sender,msg.value);
  }

   function change_statusICO(uint8 _status) public onlyAdmin{
       status=statusICO(_status);
       if(_status==1){
           timeAtStagePaused=block.timestamp;
       }
       else if(_status==2){
           totalTimePaused=block.timestamp-timeAtStagePaused;
           status=statusICO.continued;
       }
       else{
           stoppedTimer=block.timestamp;
           if(fundRaised<softCap){                                   //fundraised is lessthan soft cap, then return all investment to investors
               for(uint i;i<investors.length;i++)
               {
                   uint amount=whiteList[investors[i]].investment;
                   whiteList[investors[i]].investment=0;             // Re-entracy killer
                   (bool success,)=investors[i].call{value:amount}("");
                   require(success);                                 
               }
           }
           else
           admin.transfer(address(this).balance);
       }
   } 

}

// interface for the chainlink price_feed eth_to_usd oracle on KOVAN TESTNET
interface AggregatorV3Interface {
function latestRoundData() external view returns (uint80 roundId,int answer,uint startedAt,uint updatedAt,uint answeredInRound);
}