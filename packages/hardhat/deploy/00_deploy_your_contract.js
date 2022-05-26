// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("APPLE", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const APPLE = await ethers.getContract("APPLE", deployer);
  console.log('APPLE addr ', APPLE.address)
  
  await deploy("ColorAverager", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const ColorAverager = await ethers.getContract("ColorAverager", deployer);
  console.log('ColorAverager addr ', ColorAverager.address)
  
  
  await deploy("Base64", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const Base64 = await ethers.getContract("Base64", deployer);
  console.log('Base64 addr ', Base64.address)
  
  
  await deploy("Other_helpers", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const Other_helpers = await ethers.getContract("Other_helpers", deployer);
  console.log('Other_helpers addr ', Other_helpers.address)
  
  
  await deploy("TREE_helpers", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
    waitConfirmations: 5,
  });

  // Getting a previously deployed contract
  const TREE_helpers = await ethers.getContract("TREE_helpers", deployer);
  console.log('TREE_helpers addr ', TREE_helpers.address)
  
  await deploy("TREE", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [APPLE.address],
    log: true,
    waitConfirmations: 5,
    libraries: {
      ColorAverager: ColorAverager.address,
      Base64: Base64.address,
      Other_helpers: Other_helpers.address,
      TREE_helpers: TREE_helpers.address
    }
  });
  
  const TREE = await ethers.getContract("TREE", deployer);
  console.log('TREE addr ', TREE.address)


  // await deploy("TREE", {
  //   // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
  //   from: deployer,
  //   args: [ ],
  //   log: true,
  //   waitConfirmations: 5,
  // });
  
  // const TREE = await ethers.getContract("TREE", deployer);
  // console.log('TREE addr ', TREE.address)

  // await deploy("APPLE", {
  //   // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
  //   from: deployer,
  //   // args: [ "Hello", ethers.utils.parseEther("1.5") ],
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // // Getting a previously deployed contract
  // const APPLE = await ethers.getContract("APPLE", deployer);



  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // await yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
  // try {
  //   if (chainId !== localChainId) {
  //     await run("verify:verify", {
  //       address: YourContract.address,
  //       contract: "contracts/YourContract.sol:YourContract",
  //       constructorArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error(error);
  // }
};
module.exports.tags = ["APPLE", "TREE"];
