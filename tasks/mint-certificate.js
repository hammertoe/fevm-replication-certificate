const CID = require('cids')

task(
    "mint-certificate",
    "Mints a certificate of replication to an account for a given piece CID and one of more deal ids"
)
    .addParam("contract", "The address of the Replication Certificate NFT contract")
    .addParam("to", "The address that you want to send the minted certificate to")
    .addParam("cid", "The piece CID of the data you want a certificate for")
    .addVariadicPositionalParam("deals", "The deal id or ids for this CID")
    .setAction(async (taskArgs) => {
	const contract = taskArgs.contract;
	let deals = taskArgs.deals;
	if (!Array.isArray(deals)) {
	    deals = [deals];
	}
	
	const networkId = network.name;
        console.log("Minting NFT on network:", networkId);

	// create a new wallet instance
	const wallet = new ethers.Wallet(network.config.accounts[0], ethers.provider);

	const ReplicationCertificate = await ethers.getContractFactory("ReplicationCertificate", wallet);
	const replicationCertificate = await ReplicationCertificate.attach(contract);

	transaction = await replicationCertificate.safeMint(taskArgs.to, taskArgs.cid, deals, { gasLimit: "0x1000000" });
	transactionReceipt = await transaction.wait()

	const tokenId = transactionReceipt.logs[0].args[2] //.events[0].topics[1]
        console.log("Complete! Token ID is:", tokenId)
    });
