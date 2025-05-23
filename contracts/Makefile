# include `.env` file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

.PHONY: all test clean

# dependencies
update          	:; forge update

# install proper solc version
solc            	:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_17

# build & test
build           	:; forge build
build-optimised 	:; forge build --optimize
lint				:; yarn solhint {src,test,script}/**/*.sol && yarn solhint {src,test,script}/*.sol
lint-fix			:; yarn solhint --fix {src,test,script}/**/*.sol && yarn solhint --fix {src,test,script}/*.sol
test 				:; forge test
test-gasreport 		:; forge test --gas-report
trace           	:; forge test -vvv
clean           	:; forge clean
snapshot        	:; forge snapshot
fmt-check			:; forge fmt --check
fmt					:; forge fmt
coverage 			:; forge coverage
show-coverage 		:; forge coverage --report lcov
coverage-debug		:; forge coverage --report debug

# chmod scripts
scripts         	:; chmod +x ./script/*

# deploy
deploy-local 		:; @forge script script/${contract}.s.sol:Deploy${contract} --fork-url http://127.0.0.1:8545 --broadcast  -vvvv
deploy-sepolia 		:; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${SEPOLIA_RPC_URL} --broadcast  -vvvv
