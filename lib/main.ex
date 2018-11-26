defmodule BitcoinMain do
  def main(args) do
    args |> parse_args |> start
  end

defp parse_args(args) do
    {_,parameters,_} = OptionParser.parse(args,switches: [ name: :string],aliases: [ h: :name])
    parameters
end

  def start(parameters) do
    numUsers = String.to_integer(Enum.at(parameters,0))
    numMiners = String.to_integer(Enum.at(parameters,1))
    numTransaction = String.to_integer(Enum.at(parameters,2))
    {walletBalance, _} = Float.parse(Enum.at(parameters,3))
    IO.puts "Building your custom blockchain ecosystem"

    # spawn(Bitcoin, :start, [numUsers, numMiners, numTransaction, walletBalance])

    Bitcoin.start(numUsers, numMiners, numTransaction, walletBalance)
  end
end
