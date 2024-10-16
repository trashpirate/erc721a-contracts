
-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install https://github.com/chiru-labs/ERC721A.git --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install https://github.com/smartcontractkit/chainlink.git --no-commit && forge install transmissions11/solmate@v6 --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# test coverage
coverage:; @forge coverage --contracts src
coverage-report:; @forge coverage --contracts src --report debug > coverage.txt

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_MAIN} --fork-block-number <blocknumber> --fork-chain-id <fork id> --chain-id <custom id>

# security
slither :; slither ./src 

# deployment
deploy-local: 
	@forge script script/DeployNFTBasic.s.sol:DeployNFTBasic --rpc-url $(RPC_LOCALHOST) --private-key ${DEFAULT_ANVIL_KEY} --sender ${DEFAULT_ANVIL_ADDRESS} --broadcast 

deploy: 
	@forge script script/DeployNFTBasic.s.sol:DeployNFTBasic --rpc-url $(RPC_TEST) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# command line interaction
contract-call:
	@cast call <contract address> "FunctionSignature(params)(returns)" arguments --rpc-url ${<RPC>}

# Tron deployment
flatten:
	@forge flatten src/Contract.sol --output src/ContractFlattened.sol

-include ${FCT_PLUGIN_PATH}/makefile-external