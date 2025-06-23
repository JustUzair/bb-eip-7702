.PHONY: make-deploy

deploy-sourcify:
	forge script script/BatchCallAndSponsor.s.sol:BatchCallAndSponsorScript \
	 --rpc-url buildbear \
	 --broadcast \
	 --verifier sourcify \
	 --verify \
	 --verifier-url https://rpc.buildbear.io/verify/sourcify/server/YOUR_RPC_HERE \

deploy-etherscan:
	forge script script/BatchCallAndSponsor.s.sol:BatchCallAndSponsorScript \
		--rpc-url buildbear \
		--broadcast \
		--verifier etherscan \
		--verify \
		--etherscan-api-key "verifyContract" \
		--verifier-url https://rpc.buildbear.io/verify/etherscan/YOUR_RPC_HERE \