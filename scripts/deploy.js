const hre = require('hardhat')

async function main() {
	const WAGMIpet = await hre.ethers.getContractFactory('WAGMIpet')
	const contract = await hre.upgrades.deployProxy(WAGMIpet, ['0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8'])
	// const contract = await hre.upgrades.upgradeProxy(process.env.PROXY_ADDRESS, WAGMIpet)

	await contract.deployed()
	console.log('Contract deployed to:', contract.address)
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error)
		process.exit(1)
	})
