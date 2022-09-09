// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  // For scaffold eth frontend
  // const tx1 = await deploy("YourContract", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // await tx1.waitConfirmations();

  // const YourContract = await ethers.getContractAt("YourContract", deployer);

  await deploy("APPLE", {
    from: deployer,
    log: true,
    waitConfirmations: 5,
  });

  const APPLE = await ethers.ContractFactory.getContract("APPLE", deployer);
  console.log('APPLE addr ', APPLE.address)

  // await deploy("ColorAverager", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // const ColorAverager = await ethers.ContractFactory.getContract("ColorAverager", deployer);
  // console.log('ColorAverager addr ', ColorAverager.address)

  // await deploy("Base64", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // const Base64 = await ethers.ContractFactory.getContract("Base64", deployer);
  // console.log('Base64 addr ', Base64.address)


  // await deploy("BreedingHelpers", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // const BreedingHelpers = await ethers.ContractFactory.getContract("BreedingHelpers", deployer);
  // console.log('BreedingHelpers addr ', BreedingHelpers.address)


  // await deploy("TreeHelpers", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 5,
  // });

  // const TreeHelpers = await ethers.ContractFactory.getContract("TreeHelpers", deployer);
  // console.log('TreeHelpers addr ', TreeHelpers.address)

  // await deploy("TREE", {
  //   from: deployer,
  //   args: [APPLE.address],
  //   log: true,
  //   waitConfirmations: 5,
  //   libraries: {
  //     ColorAverager: ColorAverager.address,
  //     Base64: Base64.address,
  //     BreedingHelpers: BreedingHelpers.address,
  //     TreeHelpers: TreeHelpers.address
  //   }
  // });

  // const TREE = await ethers.ContractFactory.getContract("TREE", deployer);
  // console.log('TREE addr ', TREE.address)

  // await APPLE.update_TREE_address(TREE.address);

};

module.exports.tags = ["YourContract", "APPLE", "ColorAverager", "Base64", "BreedingHelpers", "TreeHelpers", "TREE"];
// module.exports.tags = ["YourContract"];
