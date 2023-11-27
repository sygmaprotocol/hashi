import { Chain, formatEther } from "viem"
import ABI from "../ABIs/ConnextHeaderReporterABI.json"

import BaseController from "./BaseController"

import { BaseControllerConfigs } from "./BaseController"

interface ConnextReporterControllerConfigs extends BaseControllerConfigs {}

class ConnextReporterController extends BaseController {
  constructor(_configs: ConnextReporterControllerConfigs) {
    super(_configs, "ConnextReporterController")
  }

  async onBlocks(_blockNumbers: bigint[]) {
    try {
      const client = this.multiClient.getClientByChain(this.sourceChain)

      for (const chain of this.destinationChains as Chain[]) {
        if (!this.adapterAddresses[chain.name]) continue

        const blockNumber = _blockNumbers[_blockNumbers.length - 1]

        this.logger.info(`reporting block header for block ${blockNumber} on ${chain.name} ...`)
        const { request } = await client.simulateContract({
          address: this.reporterAddresses[chain.name],
          abi: ABI,
          functionName: "reportHeaders",
          args: [[blockNumber], this.adapterAddresses[chain.name]],
        })

        const txHash = await client.writeContract(request)
        this.logger.info(`headers reporter from ${this.sourceChain.name} to ${chain.name}: ${txHash}`)
      }
    } catch (_error) {
      this.logger.error(_error)
    }
  }
}

export default ConnextReporterController
