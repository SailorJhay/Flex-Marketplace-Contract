use starknet::ContractAddress;

pub const IERC6806_ID: felt252 = 0x03b8da0c;

#[starknet::interface]
pub trait IERC6806<TState> {
    /// @notice Gets the holding time of an NFT
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the holding time of
    /// @return A tuple containing (holder_address, holding_time)
    fn holding_time(self: @TState, token_id: u256) -> (ContractAddress, u64);
    
    /// @notice Sets an exempt holder
    /// @param holder The address to set as exempt
    /// @param exempt Whether the holder is exempt
    fn set_exempt_holder(ref self: TState, holder: ContractAddress, exempt: bool);
}