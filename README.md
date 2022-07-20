# task-internship (SUNIL_ATTRI)
erc20 token is created with fixed supply
then transfer the token according to tokenomics/token distribution
send 25% token to ICO_sale contract for initial coin offering to investors for raising funds

functions in erc20 token : transfer,transferFrom,getBalance,approve

In ICO_sale contract: constructor called with token contract address 
In constructor oracle is called to get the eth_to_usd price
Chainlink price_feed oracle is used to get eth_to_usd price and oracle is deployed on kovan testnet
we can also use mainnet contract to get the external data of oracle

whitelisting investors : a struct investor_data is created with boolean allowance , investment, name of investor
                         then a mapping is created of address with the struct investor data
                         updateWhiteList Function is given in ICO contract to allow that investor address to buy tokens

buy_tokens function : input is no. of tokens to be bought 
                      all the necessary conditions are first tested through modifier
                      investment greater than investorMin_cap
                      status of Ico sale that whether it is continued or paused
                      totalpaused time is calculated 
                      
                      
fees is calculated with latest eth_to_usd price which is changed after 1 week/ 7 days only not before that

bonus structure: as given in tokenomics bonus is assigned using mapping of enum with uint

crowdsale timeline: when the sale is stopped then the fundraised is checked that whether it is greater than softCAp or not.
                    if not then transfer the fundraised to the investors back 
                    if not then transfer all the fund to the admin
                    



