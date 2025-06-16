.PHONY: make-deploy

deploy:
	forge script script/BatchCallAndSponsor.s.sol:BatchCallAndSponsorScript \
		--broadcast \
		--rpc-url buildbear \
		--verify \
		--verifier sourcify \
		--verifier-url https://rpc.test.buildbear.io/verify/sourcify/server/pectra-test
