async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(deployer.address);
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const NBMonContract = await ethers.getContractFactory("NBMonCore");
    const nbmonContract = await NBMonContract.deploy();
    await nbmonContract.deployed();
  
    console.log("Contract address:", nbmonContract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });