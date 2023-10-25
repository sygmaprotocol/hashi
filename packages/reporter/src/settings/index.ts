import "dotenv/config"

export const settings = {
  contractAddresses: {
    goerli: {
      AMBReporter: "0xedc0b1d3de4496e0d917af42f29cb71eb2982319",
      SygmaReporter: "0x2f96d347c932ac73b56e9352ecc0707e25173d88",
    },
    mainnet: {},
    gnosis: {
      AMBAdapter: "0x01268DB05965CeAc2a89566c42CD550ED7eE5ECD",
      SygmaAdapter: "0x9AD7a6f4FDA8247cC0bF5932B68c5b619937dB15",
      TelepathyLightClient: "0x34b5378DE786389a477b40dD710812c250185f83",
      TelapathyAdapter: "0x2f1E51a2763FB67fe09971Fd8d849716137A3357",
    },
  },
  reporterController: {
    ambReporterController: {
      gas: process.env.AMB_GAS,
    },
    sygmaReporterController: {
      domainID: {
        gnosis: "101",
        goerli: "1",
      },
      data: process.env.SYGMA_MSG_VALUE,
    },
    telepathyReporterController: {
      proofURL: process.env.TELEPATHY_PROOF_API_URL,
      queryBlockLength: process.env.TELEPATHY_QUERY_BLOCK_LENGTH,
      blockBuffer: process.env.TELEPATHY_BLOCK_BUFFER,
    },
  },

  blockListener: {
    queryBlockLength: process.env.QUERY_BLOCK_LENGTH,
    blockBuffer: process.env.BLOCK_BUFFER,
    timeFetchBlocksMs: process.env.TIME_FETCH_BLOCKS_MS,
  },
}
