
import {
    makeSuiteCleanRoom, owner, tomoMemeCoinFactory,ownerAddress, user, tomoMemeCoinManager, tomoMemeCoinManagerAddr
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { TomoMemeCoin__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber'

import bn from 'bignumber.js'
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 })
// returns the sqrt price as a 64x96
function encodePriceSqrt(reserve1: BigNumberish, reserve0: BigNumberish): BigNumber {
  return BigNumber.from(
    new bn(reserve1.toString())
      .div(reserve0.toString())
      .sqrt()
      .multipliedBy(new bn(2).pow(96))
      .integerValue(3)
      .toString()
  )
}

const tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600

makeSuiteCleanRoom('create ERC404', function () {
    const mintPrice = ethers.parseEther("0.01");
    const sqrtPriceX96 = encodePriceSqrt(ethers.parseEther("0.01"), ethers.parseEther("1"));
    const sqrtPriceB96 = encodePriceSqrt(ethers.parseEther("1"), ethers.parseEther("0.01"));
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to create if reserved large than supply.',   async function () {
                
                await expect(tomoMemeCoinFactory.connect(owner).createTomoMemeCoin({
                    creator: ownerAddress, 
                    totalSupply: 10000,
                    reserved: 10001,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo"
                })).to.be.revertedWithCustomError(tomoMemeCoinFactory, ERRORS.ReservedTooMuch)
            });

            it('User should fail to create twice using same param.',   async function () {
                await expect(tomoMemeCoinFactory.connect(owner).createTomoMemeCoin({
                    creator: ownerAddress, 
                    totalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo"
                })).to.be.not.reverted;
                await expect(tomoMemeCoinFactory.connect(owner).createTomoMemeCoin({
                    creator: ownerAddress, 
                    totalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo"
                })).to.be.revertedWithCustomError(tomoMemeCoinFactory, ERRORS.ContractAlreadyExist);
            });
        })

        context('Scenarios', function () {
            it('Create tomo emoji collection if pass correct param.',   async function () {
                await expect(tomoMemeCoinFactory.connect(owner).createTomoMemeCoin({
                    creator: ownerAddress, 
                    totalSupply: 10000,
                    reserved: 100,
                    maxPerWallet: 100,
                    price: mintPrice,
                    preSaleDeadLine: tomorrow,
                    sqrtPriceX96: sqrtPriceX96.toBigInt(),
                    sqrtPriceB96: sqrtPriceB96.toBigInt(),
                    name: "MoMo", 
                    symbol: "Momo"
                }, {value: ethers.parseEther("1")})).to.not.be.reverted;
            })
            it('Get correct variable tomo emoji collection if pass correct param.',     async function () {
                
                let tomoErc404Address: string
                let totalSupply = 10000
                let reserved0 = 0
                let reserved1 = 1000
                let maxPerWallet = 100
                let price0 = 0
                let price1 = mintPrice
                let name = "Tomo-emoji"
                let symbol = "Tomo-emoji"
                
                await expect(tomoMemeCoinFactory.connect(owner).createTomoMemeCoin({
                        creator: ownerAddress, 
                        totalSupply: totalSupply,
                        reserved: reserved1,
                        maxPerWallet: maxPerWallet,
                        price: mintPrice,
                        preSaleDeadLine: tomorrow,
                        sqrtPriceX96: sqrtPriceX96.toBigInt(),
                        sqrtPriceB96: sqrtPriceB96.toBigInt(),
                        name: name, 
                        symbol: symbol
                    }, {value: ethers.parseEther("15")})
                ).to.not.be.reverted;

                tomoErc404Address = await tomoMemeCoinFactory.connect(owner)._memeCoinContract(ownerAddress, name);
    
                let brc404Contract = TomoMemeCoin__factory.connect(tomoErc404Address, user);
                expect(await brc404Contract.balanceOf(tomoMemeCoinManagerAddr)).to.equal(totalSupply-reserved1);
                expect(await brc404Contract.balanceOf(ownerAddress)).to.equal(reserved1);

                expect(await ethers.provider.getBalance(tomoErc404Address)).to.equal(ethers.parseEther("10"));
            })
        })
    })
})