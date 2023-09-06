require("hardhat-deploy")
require("hardhat-deploy-ethers")

const private_key = network.config.accounts[0]
const wallet = new ethers.Wallet(private_key, ethers.provider)

module.exports = async ({ deployments }) => {
    const { deploy } = deployments;
    console.log("Wallet Ethereum Address:", wallet.address)
    const chainId = network.config.chainId
    
    //deploy ReplicationCertificate
    const replicationCetificate = await deploy("ReplicationCertificate", {
        from: wallet.address,
        args: [],
        log: true,
    });
}
