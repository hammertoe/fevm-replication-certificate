const CID = require('cids');

task(
    "add-deal",
    "Adds a deal to an existing certificate of replication for a gtiven CID"
)
    .addParam("contract", "The address of the Replication Certificate NFT contract")
    .addParam("cid", "The piece CID of the data you want a certificate for")
    .addVariadicPositionalParam("deal", "The deal id to add to this CID")
    .setAction(async (taskArgs) => {
	const contract = taskArgs.contract;
	
	const networkId = network.name;
        console.log("Adding deal to NFT on network:", networkId);
	console.log(`Adding deal ${taskArgs.deal} to piece CID ${taskArgs.cid}`);

	// create a new wallet instance
	const wallet = new ethers.Wallet(network.config.accounts[0], ethers.provider);

	const ReplicationCertificate = await ethers.getContractFactory("ReplicationCertificate", wallet);
	const replicationCertificate = await ReplicationCertificate.attach(contract);

	transaction = await replicationCertificate.addDealId(taskArgs.cid, taskArgs.deal.toString(), { gasLimit: "0x1000000" });
	transactionReceipt = await transaction.wait()

        console.log("Complete!")
    });
