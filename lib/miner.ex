defmodule Miner do

  # Elixir actor to capture all incoming transactions to mine
  def miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex) do
    receive do
      {:ok, [newTransactionData, signedMessage, senderPID, minersList]} ->
        blockChain = GenServer.call(blockChainPID, {:getBlockChain})
        latestBlock = Enum.at(blockChain, blockChainEndIndex)
        hash = Map.get(latestBlock, :hash)
        mining(blockChainPID, newTransactionData, signedMessage, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, self())
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
      {:incrementPointer} ->
        blockChainEndIndex = blockChainEndIndex + 1
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
      {:decrementPointer} ->
        blockChainEndIndex = blockChainEndIndex - 1
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
    end
  end

  # Recursively calls itself and calls the hashing function untill a hash with the specific number of 0's is found, after which it creates and adds a new block to the blockchain
  def mining(blockChainPID, transactionData, signature, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, selfPID) do
    blockChain = GenServer.call(blockChainPID, {:getBlockChain})
    cond do
      length(blockChain) - 1 > blockChainEndIndex  ->
        send selfPID, {:incrementPointer}
      length(blockChain) - 1 == blockChainEndIndex ->
            msgt_hash = Helpers.hash(transactionData, hash)
            if(String.slice(msgt_hash, 0, 4) === String.duplicate("0", 4)) do
                IO.puts "Hash found: #{inspect(msgt_hash)}"
                IO.puts "Transaction successful"
                newBlock = %{
                  transactionData: transactionData,
                  prevHash: hash,
                  hash: msgt_hash,
                  signedMessage: signature,
                  timestamp: NaiveDateTime.utc_now,
                  sendersPublicKey: Map.get(transactionData, "sendersPublicKey")
                }
                GenServer.cast(blockChainPID, {:addBlock, newBlock})
                send verificationAccumulatorPID, {:ok, senderPID, minersList}
                send selfPID, {:incrementPointer}
            else
              Miner.mining(blockChainPID, transactionData, signature, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, selfPID)
            end
    end
  end
end
