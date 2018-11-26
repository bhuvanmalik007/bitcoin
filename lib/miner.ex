defmodule Miner do
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

  def mining(blockChainPID, transactionData, signature, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, selfPID) do
    blockChain = GenServer.call(blockChainPID, {:getBlockChain})

    cond do
      length(blockChain) - 1 > blockChainEndIndex  ->
        send selfPID, {:incrementPointer}
      length(blockChain) - 1 == blockChainEndIndex ->
            msgt_hash = Miner.hash(transactionData, hash)
            if(String.slice(msgt_hash, 0, 4) === String.duplicate("0", 4)) do
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

  def randomizer(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
  end

  def hash(transactionData, prevHash) do
    # IO.puts("transaction data: #{inspect(transactionData)}")
    # IO.puts("prevHash: #{inspect(prevHash)}")
    btc = Float.to_string(Map.get(transactionData, "btc"))
    receiversPK = Map.get(transactionData, "receiversPK")
    msgt = btc <> receiversPK <> prevHash <> randomizer(9)
    :crypto.hash(:sha256, msgt) |> Base.encode16 |> String.downcase
  end

end
